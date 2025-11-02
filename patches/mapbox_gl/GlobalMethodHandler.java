package com.mapbox.mapboxgl;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Classe que lida com métodos globais do plugin Mapbox GL.
 * Versão atualizada para compatibilidade com Flutter 3.x e Android Gradle Plugin 8.x
 */
public class GlobalMethodHandler implements MethodCallHandler {
    private final MethodChannel channel;
    private Activity activity;
    private final Context context;
    private final BinaryMessenger messenger;
    private final Lifecycle lifecycle;

    // Construtor para o novo sistema de plugins (Flutter 1.12+)
    GlobalMethodHandler(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        this.context = binding.getApplicationContext();
        this.messenger = binding.getBinaryMessenger();
        this.lifecycle = null;
        
        channel = new MethodChannel(messenger, "plugins.flutter.io/mapbox_gl_global");
        channel.setMethodCallHandler(this);
    }

    // Construtor para o sistema de plugins legado (removido para compatibilidade)
    // Este construtor foi removido pois PluginRegistry.Registrar não é mais suportado

    void setActivity(@Nullable Activity activity) {
        this.activity = activity;
    }

    Lifecycle getLifecycle() {
        return lifecycle;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getMapboxApiKey")) {
            if (activity != null) {
                result.success(getMapboxApiKey(activity));
            } else {
                result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null);
            }
        } else {
            result.notImplemented();
        }
    }

    private String getMapboxApiKey(Activity activity) {
        try {
            android.content.pm.ApplicationInfo appInfo = activity.getPackageManager()
                    .getApplicationInfo(activity.getPackageName(), android.content.pm.PackageManager.GET_META_DATA);
            
            if (appInfo.metaData != null) {
                String apiKey = appInfo.metaData.getString("com.mapbox.token");
                if (apiKey != null && !apiKey.isEmpty()) {
                    return apiKey;
                }
            }
            return "";
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
    }
}
