// ExportFunctions.java — Ghidra headless postScript.
// Emits the analyzed program's functions as a JSON seed list for the
// ndsrecomp discovery pass. Compatible with all Ghidra versions (including 12+).
//@category RecompNDS

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.address.Address;
import ghidra.program.model.lang.Register;
import ghidra.program.model.lang.RegisterValue;

import java.io.PrintWriter;
import java.io.FileWriter;
import java.io.File;

public class ExportFunctions extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String outPath = (args != null && args.length > 0) ? args[0] : "ghidra_functions.json";

        FunctionManager fm = currentProgram.getFunctionManager();
        Register tmode = currentProgram.getProgramContext().getRegister("TMode");

        File outFile = new File(outPath);
        File parent = outFile.getParentFile();
        if (parent != null) {
            parent.mkdirs();
        }

        try (PrintWriter writer = new PrintWriter(new FileWriter(outFile))) {
            writer.println("[");
            FunctionIterator iter = fm.getFunctions(true);
            boolean first = true;
            int count = 0;
            while (iter.hasNext()) {
                Function fn = iter.next();
                Address entry = fn.getEntryPoint();
                String mode = "arm";
                if (tmode != null) {
                    RegisterValue val = currentProgram.getProgramContext().getRegisterValue(tmode, entry);
                    if (val != null && val.hasValue() && val.getUnsignedValueIgnoreMask() != null && val.getUnsignedValueIgnoreMask().longValue() != 0) {
                        mode = "thumb";
                    }
                }

                if (!first) {
                    writer.println(",");
                }
                first = false;

                String escapedName = fn.getName().replace("\\", "\\\\").replace("\"", "\\\"");
                writer.print(String.format(" {\n  \"addr\": \"0x%08X\",\n  \"name\": \"%s\",\n  \"mode\": \"%s\"\n }",
                    entry.getOffset(), escapedName, mode));
                count++;
            }
            writer.println("\n]");
            println("ExportFunctions: wrote " + count + " functions to " + outPath);
        }
    }
}
