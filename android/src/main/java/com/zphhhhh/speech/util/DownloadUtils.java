package com.zphhhhh.speech.util;

import android.content.Context;

import com.zphhhhh.speech.impl.DownloadCallback;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

public class DownloadUtils {

    /**
     * http://182.86.209.83:8090/group2/M08/27/91/wKgNSF_-poWAGLTjAAQt1DwlAF4667.wav
     *
     * @return context.getExternalCacheDir() + "/wKgNSF_-poWAGLTjAAQt1DwlAF4667.wav"
     */
    public static void downloadFile(final Context context, final String url, final DownloadCallback callback) {
        /**
         * 本地文件
         */
        if (!url.startsWith("http")) {
            callback.success(url);
            return;
        }

        /**
         * 网络文件
         * 定义本地存储路径
         */
        final String localFilePath = context.getExternalCacheDir() + url.substring(url.lastIndexOf("/"), url.length());
        final File localFile = new File(localFilePath);

        /**
         * 本地有缓存
         */
        if (localFile.exists() && localFile.length() > 1) {
            callback.success(localFilePath);
            return;
        }

        /**
         * 本地没有缓存
         */
        new Thread(new Runnable() {
            @Override
            public void run() {
                BufferedInputStream bis = null;
                BufferedOutputStream bos = null;
                try {
                    localFile.createNewFile();
                    URL urlfile = new URL(url);
                    HttpURLConnection httpUrl = (HttpURLConnection) urlfile.openConnection();
                    httpUrl.connect();
                    bis = new BufferedInputStream(httpUrl.getInputStream());
                    bos = new BufferedOutputStream(new FileOutputStream(localFile));
                    int len = 2048;
                    byte[] b = new byte[len];
                    while ((len = bis.read(b)) != -1) {
                        bos.write(b, 0, len);
                    }
                    System.out.println("下载成功");
                    callback.success(localFilePath);
                    bos.flush();
                    bis.close();
                    httpUrl.disconnect();
                } catch (Exception e) {
                    callback.failed();
                    e.printStackTrace();
                } finally {
                    try {
                        bis.close();
                        bos.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }).start();
    }
}
