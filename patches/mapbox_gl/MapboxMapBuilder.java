package com.mapbox.mapboxgl;

import android.content.Context;
import androidx.annotation.NonNull;
import java.util.Map;
import java.util.List;
import java.util.HashMap;

import io.flutter.plugin.common.BinaryMessenger;

/**
 * Construtor para instâncias de MapboxMapController.
 * Versão atualizada para compatibilidade com Flutter 3.x e Android Gradle Plugin 8.x
 */
public class MapboxMapBuilder {
    private boolean trackCameraPosition = false;
    private boolean myLocationEnabled = false;
    private int myLocationTrackingMode = 0;
    private int myLocationRenderMode = 0;
    private String styleString = null;
    private boolean compassEnabled = true;
    private boolean attributionButtonEnabled = false;
    private boolean logoEnabled = true;
    private boolean rotateGesturesEnabled = true;
    private boolean scrollGesturesEnabled = true;
    private boolean tiltGesturesEnabled = true;
    private boolean zoomGesturesEnabled = true;
    private boolean doubleClickZoomEnabled = true;
    private boolean dragEnabled = true;

    /**
     * Interpreta as opções recebidas do Flutter
     */
    @SuppressWarnings("unchecked")
    static String interpretOptions(Object options, MapboxMapBuilder builder) {
        final Map<String, Object> optionsMap = (Map<String, Object>) options;
        String accessToken = (String) optionsMap.get("accessToken");
        
        builder.trackCameraPosition = (Boolean) optionsMap.get("trackCameraPosition");
        builder.myLocationEnabled = (Boolean) optionsMap.get("myLocationEnabled");
        builder.myLocationTrackingMode = (Integer) optionsMap.get("myLocationTrackingMode");
        builder.myLocationRenderMode = (Integer) optionsMap.get("myLocationRenderMode");
        builder.compassEnabled = (Boolean) optionsMap.get("compassEnabled");
        builder.attributionButtonEnabled = (Boolean) optionsMap.get("attributionEnabled");
        builder.logoEnabled = (Boolean) optionsMap.get("logoEnabled");
        builder.styleString = (String) optionsMap.get("styleString");
        builder.rotateGesturesEnabled = (Boolean) optionsMap.get("rotateGesturesEnabled");
        builder.scrollGesturesEnabled = (Boolean) optionsMap.get("scrollGesturesEnabled");
        builder.tiltGesturesEnabled = (Boolean) optionsMap.get("tiltGesturesEnabled");
        builder.zoomGesturesEnabled = (Boolean) optionsMap.get("zoomGesturesEnabled");
        builder.doubleClickZoomEnabled = (Boolean) optionsMap.get("doubleClickZoomEnabled");
        builder.dragEnabled = (Boolean) optionsMap.get("dragEnabled");
        
        return accessToken;
    }

    /**
     * Constrói um MapboxMapController com as opções configuradas
     */
    MapboxMapController build(
            int id, Context context, BinaryMessenger messenger, MapboxMapsPlugin.LifecycleProvider lifecycleProvider, String accessToken) {
        final MapboxMapController controller =
                new MapboxMapController(
                        id,
                        context,
                        messenger,
                        lifecycleProvider,
                        accessToken,
                        styleString,
                        new MapboxMapOptions()
                                .compassEnabled(compassEnabled)
                                .attributionEnabled(attributionButtonEnabled)
                                .logoEnabled(logoEnabled)
                                .rotateGesturesEnabled(rotateGesturesEnabled)
                                .scrollGesturesEnabled(scrollGesturesEnabled)
                                .tiltGesturesEnabled(tiltGesturesEnabled)
                                .zoomGesturesEnabled(zoomGesturesEnabled)
                                .doubleClickZoomEnabled(doubleClickZoomEnabled)
                                .dragEnabled(dragEnabled));
        
        controller.init();
        return controller;
    }
    
    /**
     * Classe interna para representar as opções do mapa
     */
    static class MapboxMapOptions {
        private final Map<String, Object> options = new HashMap<>();
        
        MapboxMapOptions compassEnabled(boolean enabled) {
            options.put("compassEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions attributionEnabled(boolean enabled) {
            options.put("attributionEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions logoEnabled(boolean enabled) {
            options.put("logoEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions rotateGesturesEnabled(boolean enabled) {
            options.put("rotateGesturesEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions scrollGesturesEnabled(boolean enabled) {
            options.put("scrollGesturesEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions tiltGesturesEnabled(boolean enabled) {
            options.put("tiltGesturesEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions zoomGesturesEnabled(boolean enabled) {
            options.put("zoomGesturesEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions doubleClickZoomEnabled(boolean enabled) {
            options.put("doubleClickZoomEnabled", enabled);
            return this;
        }
        
        MapboxMapOptions dragEnabled(boolean enabled) {
            options.put("dragEnabled", enabled);
            return this;
        }
        
        Map<String, Object> getOptions() {
            return options;
        }
    }
}
