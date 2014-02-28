
var smartCompare = xdc.loadCapsule('SmartCompare.xs');

function main(arg) {

    var outFile = arg[0];
    var goldenFile = arg[1];
    var resultsFile = arg[2];

    if ((outFile != "") && (goldenFile != "")) {

        var fos1 = new java.io.FileOutputStream(resultsFile);
        var retFile = new java.io.BufferedWriter(new java.io.OutputStreamWriter(fos1));

        try {
            var fis1 = new java.io.FileInputStream(outFile);
            var file1 = new java.io.BufferedReader(new java.io.InputStreamReader(fis1));

            var fis2 = new java.io.FileInputStream(goldenFile);
            var file2 = new java.io.BufferedReader(new java.io.InputStreamReader(fis2));

            retString = smartCompare.smartComp(file1, file2);
            if (retString != null) {
                retFile.write(retString);
            }
        }
        catch (e) {
            retFile.write("JS exception: " + e);
        }

        retFile.close();
    }

    return 0;
}
