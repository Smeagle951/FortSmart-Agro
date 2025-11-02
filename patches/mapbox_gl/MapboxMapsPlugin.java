package com.mapbox.mapboxgl;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference;

/**
 * Plugin para integração do Mapbox GL no Flutter.
 * Versão atualizada para compatibilidade com Flutter 3.x e Android Gradle Plugin 8.x
 */
public class MapboxMapsPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    private MethodChannel channel;
    private Activity activity;
    private Application application;
    private Lifecycle lifecycle;
    private GlobalMethodHandler methodHandler;
    private MapboxMapFactory mapboxMapFactory;
    public static FlutterAssets flutterAssets;

    // Interface para fornecer o lifecycle para os componentes do mapa
    public interface LifecycleProvider {
        Lifecycle getLifecycle();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "plugins.flutter.io/mapbox_gl");
        channel.setMethodCallHandler(this);
        
        methodHandler = new GlobalMethodHandler(binding);
        mapboxMapFactory = new MapboxMapFactory(binding.getBinaryMessenger(), new LifecycleProvider() {
            @Override
            public Lifecycle getLifecycle() {
                return lifecycle;
            }
        });
        binding.getPlatformViewRegistry()
                .registerViewFactory("plugins.flutter.io/mapbox_gl", mapboxMapFactory);
                
        flutterAssets = binding.getFlutterAssets();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        application = activity.getApplication();
        lifecycle = ((HiddenLifecycleReference) binding.getLifecycle()).getLifecycle();
        methodHandler.setActivity(activity);
        // Não precisa mais chamar setLifecycle, pois agora usamos o LifecycleProvider
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
        application = null;
        lifecycle = null;
        methodHandler.setActivity(null);
        // Não precisa mais chamar setLifecycle, pois agora usamos o LifecycleProvider
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else {
            result.notImplemented();
        }
    }

    // Método para compatibilidade com versões antigas do Flutter foi removido
    // O sistema de plugins legado não é mais suportado pelo Flutter 3.x
}
