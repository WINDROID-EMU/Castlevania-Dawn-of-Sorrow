package com.windroid.castlevania;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

public class TitleActivity extends Activity {
    private static final String TAG = "TitleActivity";
    private static final int REQUEST_PICK_ROM = 1001;
    private static final int REQUEST_STORAGE_PERMISSION = 1002;
    private static final int REQUEST_MANAGE_STORAGE = 1003;

    private TextView tvPressStart;
    private TextView tvRomStatus;
    private Button btnSelectRom;
    private String detectedRomPath = null;
    private MediaPlayer mediaPlayer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        enableImmersiveMode();
        setContentView(R.layout.activity_title);

        tvPressStart = findViewById(R.id.tv_press_start);
        tvRomStatus = findViewById(R.id.tv_rom_status);
        btnSelectRom = findViewById(R.id.btn_select_rom);

        Animation pulse = AnimationUtils.loadAnimation(this, R.anim.pulse);
        tvPressStart.startAnimation(pulse);

        initMusic();
        requestStoragePermissionIfNeeded();
        checkRomAvailability();

        View root = findViewById(R.id.root_title_layout);
        root.setOnClickListener(v -> onScreenTapped());

        btnSelectRom.setOnClickListener(v -> {
            if (!hasStoragePermission()) {
                requestStoragePermissionIfNeeded();
            } else {
                openRomPicker();
            }
        });
    }

    private void initMusic() {
        try {
            mediaPlayer = MediaPlayer.create(this, R.raw.title_theme);
            if (mediaPlayer != null) {
                mediaPlayer.setLooping(true);
                mediaPlayer.setVolume(0.85f, 0.85f);
                mediaPlayer.start();
                Log.i(TAG, "Title music (Requiem for the Throne) started successfully!");
            } else {
                Log.e(TAG, "MediaPlayer.create returned null for R.raw.title_theme");
            }
        } catch (Exception e) {
            Log.e(TAG, "Erro ao iniciar musica: " + e.getMessage(), e);
        }
    }

    private void stopAndReleaseMusic() {
        if (mediaPlayer != null) {
            try {
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.stop();
                }
                mediaPlayer.release();
            } catch (Exception ignored) {}
            mediaPlayer = null;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        enableImmersiveMode();
        checkRomAvailability();
        if (mediaPlayer != null && !mediaPlayer.isPlaying()) {
            mediaPlayer.start();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            mediaPlayer.pause();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopAndReleaseMusic();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            enableImmersiveMode();
        }
    }

    private void enableImmersiveMode() {
        View decorView = getWindow().getDecorView();
        decorView.setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        );

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            WindowManager.LayoutParams lp = getWindow().getAttributes();
            lp.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            getWindow().setAttributes(lp);
        }
    }

    private boolean hasStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager();
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED;
        }
        return true;
    }

    private void requestStoragePermissionIfNeeded() {
        if (hasStoragePermission()) {
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                intent.setData(Uri.parse("package:" + getPackageName()));
                startActivityForResult(intent, REQUEST_MANAGE_STORAGE);
            } catch (Exception e) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                startActivityForResult(intent, REQUEST_MANAGE_STORAGE);
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(new String[]{
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            }, REQUEST_STORAGE_PERMISSION);
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_STORAGE_PERMISSION) {
            checkRomAvailability();
        }
    }

    private void checkRomAvailability() {
        String[] candidatePaths = new String[] {
            new File(getFilesDir(), "game.nds").getAbsolutePath(),
            new File(getFilesDir(), "Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(getExternalFilesDir(null), "game.nds").getAbsolutePath(),
            new File(getExternalFilesDir(null), "Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Castlevania/game.nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Castlevania/Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Download/Castlevania - Dawn of Sorrow .nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "Download/game.nds").getAbsolutePath(),
            new File(Environment.getExternalStorageDirectory(), "game.nds").getAbsolutePath(),
            "/storage/emulated/0/Castlevania/game.nds",
            "/storage/emulated/0/Download/Castlevania - Dawn of Sorrow .nds",
            "/storage/emulated/0/Download/game.nds"
        };

        detectedRomPath = null;
        for (String path : candidatePaths) {
            File f = new File(path);
            if (f.exists() && f.length() > 0) {
                detectedRomPath = path;
                break;
            }
        }

        if (detectedRomPath != null) {
            tvRomStatus.setText("✓ ROM Pronta (" + new File(detectedRomPath).getName() + ")");
            btnSelectRom.setVisibility(View.GONE);
            tvPressStart.setText("— TOCAR PARA INICIAR —");
        } else {
            if (!hasStoragePermission()) {
                tvRomStatus.setText("Permissão de arquivos necessária para ler a ROM");
                btnSelectRom.setText("Conceder Permissão / Selecionar ROM");
            } else {
                tvRomStatus.setText("Coloque a ROM na pasta Download/ ou selecione abaixo");
                btnSelectRom.setText("Selecionar ROM (.nds)");
            }
            btnSelectRom.setVisibility(View.VISIBLE);
            tvPressStart.setText("PRESSIONE INICIAR");
        }
    }

    private void onScreenTapped() {
        if (detectedRomPath != null) {
            launchGame(detectedRomPath);
        } else if (!hasStoragePermission()) {
            requestStoragePermissionIfNeeded();
        } else {
            openRomPicker();
        }
    }

    private void openRomPicker() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        startActivityForResult(intent, REQUEST_PICK_ROM);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_MANAGE_STORAGE || requestCode == REQUEST_STORAGE_PERMISSION) {
            checkRomAvailability();
        } else if (requestCode == REQUEST_PICK_ROM && resultCode == RESULT_OK && data != null) {
            Uri uri = data.getData();
            if (uri != null) {
                copySelectedRomAndLaunch(uri);
            }
        }
    }

    private void copySelectedRomAndLaunch(Uri uri) {
        tvRomStatus.setText("Carregando ROM...");
        new Thread(() -> {
            try {
                File dest = new File(getFilesDir(), "game.nds");
                try (InputStream in = getContentResolver().openInputStream(uri);
                     OutputStream out = new FileOutputStream(dest)) {
                    byte[] buf = new byte[65536];
                    int len;
                    while ((len = in.read(buf)) != -1) {
                        out.write(buf, 0, len);
                    }
                }
                runOnUiThread(() -> {
                    detectedRomPath = dest.getAbsolutePath();
                    launchGame(detectedRomPath);
                });
            } catch (Exception e) {
                Log.e(TAG, "Erro ao copiar ROM: " + e.getMessage(), e);
                runOnUiThread(() -> {
                    Toast.makeText(this, "Erro ao abrir ROM: " + e.getMessage(), Toast.LENGTH_LONG).show();
                    checkRomAvailability();
                });
            }
        }).start();
    }

    private void launchGame(String romPath) {
        stopAndReleaseMusic();
        Intent intent = new Intent(this, CastlevaniaActivity.class);
        intent.putExtra("ROM_PATH", romPath);
        startActivity(intent);
        overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
        finish();
    }
}
