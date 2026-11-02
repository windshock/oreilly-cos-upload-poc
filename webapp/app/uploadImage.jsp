<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.io.*"%>
<%@ page import="com.oreilly.servlet.MultipartRequest"%>
<%@ page import="com.oreilly.servlet.multipart.*"%>
<%!
    // A typical legacy image-upload validator.
    boolean chkContent(String t){
        return t.equals("image/jpeg")||t.equals("image/pjpeg")||t.equals("image/gif")
             ||t.equals("image/x-png")||t.equals("image/png");
    }
    boolean chkExt(String f){
        String e=f.substring(f.lastIndexOf(".")+1).toLowerCase();
        return e.equals("jpg")||e.equals("jpeg")||e.equals("gif")||e.equals("png");
    }
%>
<%
    int maxSize = 1024*1024;
    // Upload dir lives UNDER the webapp root -> served by the JSP engine.
    // (This models the real-world condition where the upload area is inside a
    //  JSP-executing context. If a fronting static server served it instead,
    //  the impact would be stored-XSS rather than code execution.)
    String realFolder = application.getRealPath("/") + "/uploads";
    new File(realFolder).mkdirs();

    try {
        // FLAW #1 (by design in COS push model, documented in its javadoc/FAQ):
        // the constructor writes EVERY file part to disk BEFORE any check runs.
        MultipartRequest multi =
            new MultipartRequest(request, realFolder, maxSize, "UTF-8", new DefaultFileRenamePolicy());

        // FLAW #2 (application bug): only the FIRST file is inspected...
        Enumeration files = multi.getFileNames();
        String name = (String) files.nextElement();
        String filename = multi.getFilesystemName(name);
        String type = multi.getContentType(name);

        if (!chkExt(filename) || !chkContent(type)) {
            // ...and on failure only THAT one file is removed; the rest stay on disk.
            File bad = new File(realFolder + "/" + filename);
            if (bad.exists()) bad.delete();
            out.println("REJECTED: " + filename + " (only jpg/jpeg/gif/png allowed)");
            return;
        }
        out.println("ACCEPTED: " + filename);
    } catch (Exception e) {
        out.println("ERR: " + e.getMessage());
    }
%>
