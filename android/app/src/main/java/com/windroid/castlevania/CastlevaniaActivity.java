package com.windroid.castlevania;

import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import org.libsdl.app.SDLActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;

public class CastlevaniaActivity extends SDLActivity {
    private static final String TAG = "CastlevaniaRecomp";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        copyAssetIfNeeded("game.toml");
        copyAssetIfNeeded("firmware.bin");
        super.onCreate(savedInstanceState);
        getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            getWindow().setSustainedPerformanceMode(true);
        }
    }

    @Override
    protected String[] getLibraries() {
        return new String[] {
            "SDL3",
            "main"
        };
    }

    @Override
    protected String[] getArguments() {
        File filesDir = getFilesDir();
        File configFile = new File(filesDir, "game.toml");

        // Candidates for ROM location
        String[] candidatePaths = new String[] {
            new File(filesDir, "game.nds").getAbsolutePath(),
            new File(filesDir, "Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(getExternalFilesDir(null), "game.nds").getAbsolutePath(),
            new File(getExternalFilesDir(null), "Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Castlevania/game.nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Download/Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Download/game.nds").getAbsolutePath(),
            "/storage/emulated/0/Castlevania/game.nds",
            "/storage/emulated/0/Download/Castlevania - Dawn of Sorrow .nds"
        };

        String selectedRom = "";
        String passedRom = getIntent() != null ? getIntent().getStringExtra("ROM_PATH") : null;
        if (passedRom != null && new File(passedRom).exists() && new File(passedRom).length() > 0) {
            selectedRom = passedRom;
            Log.i(TAG, "Using passed ROM from Intent: " + selectedRom);
        } else {
            for (String path : candidatePaths) {
                File f = new File(path);
                if (f.exists() && f.length() > 0) {
                    selectedRom = path;
                    Log.i(TAG, "Found Castlevania ROM at: " + selectedRom);
                    break;
                }
            }
        }

        List<String> args = new ArrayList<>();
        args.add(filesDir.getAbsolutePath());
        args.add("--freebios");
        args.add("--boot");
        args.add("direct");
        args.add("--generated-firmware");
        args.add("--interactive");


        if (configFile.exists()) {
            args.add("--config");
            args.add(configFile.getAbsolutePath());
        }

        if (!selectedRom.isEmpty()) {
            args.add("--rom");
            args.add(selectedRom);
        } else {
            // Default expected path in app private files
            File defaultRom = new File(filesDir, "game.nds");
            args.add("--rom");
            args.add(defaultRom.getAbsolutePath());
            Log.w(TAG, "ROM not found yet; defaulting to: " + defaultRom.getAbsolutePath());
        }

        File saveDir = new File(filesDir, "saves");
        if (!saveDir.exists()) {
            saveDir.mkdirs();
        }
        File saveFile = new File(saveDir, "game.sav");
        args.add("--save-path");
        args.add(saveFile.getAbsolutePath());

        Log.i(TAG, "Launch args: " + args.toString());
        return args.toArray(new String[0]);
    }

    private void copyAssetIfNeeded(String assetName) {
        File outFile = new File(getFilesDir(), assetName);
        if (outFile.exists() && outFile.length() > 0) {
            return;
        }
        try (InputStream in = getAssets().open(assetName);
             OutputStream out = new FileOutputStream(outFile)) {
            byte[] buf = new byte[8192];
            int read;
            while ((read = in.read(buf)) != -1) {
                out.write(buf, 0, read);
            }
            Log.i(TAG, "Copied asset " + assetName + " to " + outFile.getAbsolutePath());
        } catch (Exception e) {
            Log.e(TAG, "Failed copying asset " + assetName + ": " + e.getMessage());
        }
    }
}
