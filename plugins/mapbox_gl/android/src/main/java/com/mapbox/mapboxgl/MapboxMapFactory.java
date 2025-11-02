package com.mapbox.mapboxgl;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.lifecycle.Lifecycle;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

/**
 * Factory para criar instâncias de MapboxMapController.
 * Versão atualizada para compatibilidade com Flutter 3.x e Android Gradle Plugin 8.x
 */
public class MapboxMapFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;
    private final MapboxMapsPlugin.LifecycleProvider lifecycleProvider;

    public MapboxMapFactory(BinaryMessenger messenger, MapboxMapsPlugin.LifecycleProvider lifecycleProvider) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.lifecycleProvider = lifecycleProvider;
    }

    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        final MapboxMapBuilder builder = new MapboxMapBuilder();
        String accessToken = null;

        if (args != null) {
            accessToken = MapboxMapBuilder.interpretOptions(args, builder);
        }

        return builder.build(
                viewId,
                context,
                messenger,
                lifecycleProvider,
                accessToken);
    }
}
