package com.zphhhhh.speech;

import android.content.Context;

import java.io.File;
import java.io.IOException;

public class AndroidAudioConverterManager {
    private Context context;
    private static AndroidAudioConverterManager instance;

    public static AndroidAudioConverterManager getInstance() {
        if (instance == null) {
            instance = new AndroidAudioConverterManager();
        }
        return instance;
    }

    public String getConvertedFile(String path){
        File originalFile=new File(path);
        String[] f = originalFile.getPath().split("\\.");
        String filePath = originalFile.getPath().replace(f[f.length - 1], "wav");
        File newFile=new File(filePath);
        if (!newFile.exists()){
            newFile.getParentFile().mkdirs();
            try {
                newFile.createNewFile();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return filePath;
    }
}
