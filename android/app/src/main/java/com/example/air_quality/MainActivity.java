package com.example.air_quality;

import android.content.Intent;
import android.net.Uri;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String DEEP_LINK_CHANNEL = "airquality.deeplink";
    private MethodChannel methodChannel;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // Ensure Flutter plugins are registered (required when overriding configureFlutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DEEP_LINK_CHANNEL);
        
        methodChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "getInitialLink":
                    String initialLink = getInitialLink();
                    result.success(initialLink);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleDeepLink(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        Intent intent = getIntent();
        if (intent != null) {
            handleDeepLink(intent);
        }
    }

    private void handleDeepLink(Intent intent) {
        Uri data = intent.getData();
        if (data != null && methodChannel != null) {
            String link = data.toString();
            methodChannel.invokeMethod("onDeepLink", link);
        }
    }

    private String getInitialLink() {
        Intent intent = getIntent();
        if (intent != null) {
            Uri data = intent.getData();
            if (data != null) {
                return data.toString();
            }
        }
        return null;
    }
}
