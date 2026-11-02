# The O'Reilly Curse — when book sample code ends up running in production

A small, self-contained lab that shows how a **20-year-old file-upload helper**
— shipped as the companion code to a classic O'Reilly book — turns a sloppy
upload validator into **arbitrary file upload with code execution** (CWE-434).

The uploaded payload here only prints `HELLO-FROM-UPLOADED-JSP`. There is **no
command execution, no shell, no data access** anywhere in this repo. It is an
educational / authorized-testing artifact, not a weapon.

> ⚠️ Use only against systems you own or are authorized to test.

## Blog posts

- English: https://windshock.github.io/en/post/2026-11-02-oreilly-cos-upload-curse/
- Korean (한국어): https://windshock.github.io/ko/post/2026-11-02-oreilly-cos-upload-curse/

## The thesis

Sample code in books and tutorials is written for **clarity**, not for
production security. The problem is not that the authors were careless — it is
that this code gets **copy-pasted into real systems** and then outlives everyone
who remembers where it came from.

`com.oreilly.servlet` ("COS") is the exhibit. It is the companion library to
Jason Hunter's *Java Servlet Programming* (O'Reilly). Last released in
**2002/2005**, unmaintained ever since — yet it still rides along inside modern
WARs as a transitive/ghost dependency.

## Two things stack up

**1. A documented design choice (not a bug, not a CVE).**
The COS "push" model `MultipartRequest` **writes every uploaded part to disk in
its constructor, before your code can inspect anything.** This is stated in its
own javadoc/FAQ; the author explicitly tells you to use the `MultipartParser`
"pull" model (or a temp dir) if you need to validate before committing files.

```jsp
// the constructor has ALREADY saved every file to realFolder by this point:
MultipartRequest multi =
    new MultipartRequest(request, realFolder, maxSize, "UTF-8", new DefaultFileRenamePolicy());
```

**2. A very common application mistake.**
A typical validator checks **only the first file** and, on failure, deletes
**only that one**:

```jsp
String name = (String) multi.getFileNames().nextElement(); // only the FIRST
if (!chkExt(filename) || !chkContent(type)) {
    new File(realFolder + "/" + filename).delete();         // delete only that one
    return;                                                  // the rest stay on disk
}
```

Send a multipart request with a valid image **plus** a non-image file, and the
non-image file survives on disk. If that directory is served by a JSP-executing
context, the file runs. (COS stores parts in a `Hashtable`, so which one gets
checked is non-deterministic — upload two and at least one always survives.)

## CVE ≠ CWE

There is **no published CVE** for COS (confirmed via NVD/MITRE/Snyk). "No CVE"
does **not** mean safe:

| | COS (this repo's subject) | commons-fileupload 1.2.1 (contrast) |
|---|---|---|
| Published CVE | none — it's **code misuse (CWE-434)** | yes (CVE-2014-0050, 2016-3092, 2023-24998) |
| Trigger | only when the vulnerable endpoint is called | every multipart request (auto, pre-auth) |
| Fix | **change the code** (upgrading the jar won't help) | upgrade / switch resolver |

The maintained COS fork keeps the same push-model behavior — so **upgrading the
library does not fix this.** The fix is in how you use it.

## Run the lab

Requires Docker.

```bash
scripts/fetch-cos.sh   # downloads the public cos.jar from Maven Central (not committed)
scripts/run.sh         # Tomcat 8.5 on http://localhost:8899/
scripts/demo.sh        # baseline reject -> validation bypass -> hello-world executes
docker rm -f cos-poc   # cleanup
```

Expected: a single `.jsp` is rejected; but a multipart request mixing a valid
`.gif` with `.jsp` files leaves a `.jsp` on disk that then returns
`HELLO-FROM-UPLOADED-JSP`.

## The right way

- Validate **before** committing to a permanent location: COS `MultipartParser`
  (pull model), or Spring `StandardServletMultipartResolver` / Jakarta
  `Part` API, writing to a temp dir and moving only after checks pass.
- Allow-list by **content**, not just extension; generate your own filename;
  never keep the client's extension.
- Store uploads **outside any script-executing context** (a static origin, or
  object storage), and block script execution in the upload path.
- Inventory legacy jars. A library used in exactly one file can still ship in
  every WAR. "It compiles and runs" is not "it's safe" — especially for code
  that was written to *teach*.

## Detect it in your own code

```bash
# COS usage (note: EUC-KR/legacy JSPs can be misclassified as binary — use -a)
grep -ran "com.oreilly.servlet" --include='*.jsp' --include='*.java' .
# the first-file-only anti-pattern
grep -rn "getFileNames().nextElement()" --include='*.jsp' .
```

## This is not novel — prior art

This lab documents a *well-known* class of problem, not a new discovery. If you
arrived here thinking "surely others have said this," you're right:

- **The behavior is documented by the author.** COS's own javadoc/FAQ state that
  `MultipartRequest` saves files during construction and recommend the
  `MultipartParser` pull model (or a temp dir) when you need to validate first.
- **KISA (KrCERT) published a Web Editor Security Guide** that explicitly covers
  upload vulnerabilities in common web editors — including DaumEditor, the exact
  editor whose bundled `uploadImage.jsp` so often wires COS up this way.
- **Multipart validation-bypass is a studied attack class** (parser
  discrepancies, duplicate `filename`/`filename*`, multiple parts where only one
  is checked), and arbitrary upload → execution is **CWE-434 / OWASP File Upload**.

The contribution here is only the framing ("book sample code as a ghost
dependency") and a minimal, benign, reproducible demonstration.

## References

- KISA/KrCERT — 웹 에디터 보안 가이드 (Web Editor Security Guide, 2022-11-07):
  https://boho.or.kr/kr/bbs/view.do?searchCnd=1&bbsId=B0000127&searchWrd=&menuNo=205021&pageIndex=5&categoryCode=&nttId=67020
- COS `MultipartRequest` javadoc (constructor saves on parse):
  https://www.servlets.com/cos/javadoc/com/oreilly/servlet/MultipartRequest.html
- servlets.com — COS FAQ (validation ordering guidance): https://www.servlets.com/cos/faq.html
- Snyk — `servlets.com:cos` has no listed vulnerabilities (CVE ≠ safe):
  https://security.snyk.io/package/maven/servlets.com:cos
- sicuranext — Breaking Down Multipart Parsers: File upload validation bypass:
  https://blog.sicuranext.com/breaking-down-multipart-parsers-validation-bypass/
- OWASP — File Upload Cheat Sheet:
  https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- MITRE — CWE-434: Unrestricted Upload of File with Dangerous Type:
  https://cwe.mitre.org/data/definitions/434.html
- Maintained Jakarta fork (same push-model behavior): https://github.com/easy-4-java/cos
- Artifact: https://mvnrepository.com/artifact/servlets.com/cos

## License

MIT. Educational use.
