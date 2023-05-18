package com.zphhhhh.speech.util;

import android.content.Context;
import android.media.MediaPlayer;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.Promise;
import com.zphhhhh.speech.impl.DownloadCallback;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

public class MediaPlayerManager {
    private static MediaPlayerManager mediaPlayerManager;
    private MediaPlayer player = new MediaPlayer();

    public static MediaPlayerManager getInstance() {
        if (mediaPlayerManager == null) {
            mediaPlayerManager = new MediaPlayerManager();
        }
        return mediaPlayerManager;
    }

    public void play(final String path, final Context context, final Promise promise) {
        if (player.isPlaying()) {
            return;
        }
        player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {

            @Override
            public void onCompletion(MediaPlayer mp) {
                if (promise != null) {
                    promise.resolve("true");
                }
            }
        });
        /**
         * path -> localPath
         */
        DownloadUtils.downloadFile(context, path, new DownloadCallback() {
            @Override
            public void success(String localPath) {
                /**
                 * 播放语音
                 */
                try {
                    player.reset();
                    player.setDataSource(localPath);
                    player.prepare();

                    player.start();
                } catch (Exception e) {
                    Toast.makeText(context, "播放失败", Toast.LENGTH_SHORT).show();
                    Log.e("MediaPlayerManager", e.toString());
                }
            }

            @Override
            public void failed() {
                Toast.makeText(context, "语音文件下载失败", Toast.LENGTH_SHORT).show();
            }
        });

    }

    public void stopPlay() {
        if (player.isPlaying()) {
            player.stop();
        }
    }

    //获取语音时长
    public void getVoiceDuration(final Context context, final String path, final Promise promise) {
        /**
         * path -> localPath
         */
        DownloadUtils.downloadFile(context, path, new DownloadCallback() {
            @Override
            public void success(String localPath) {
                /**
                 * 计算时长
                 */
                MediaPlayer mediaPlayer = new MediaPlayer();
                try {
                    File file = new File(localPath);
                    FileInputStream fis = new FileInputStream(file);
                    mediaPlayer.setDataSource(fis.getFD());
                    mediaPlayer.prepare();
                    if (promise != null) {
                        promise.resolve(mediaPlayer.getDuration());
                    }
                } catch (IOException e) {
                    if (promise != null) {
                        promise.reject(e.toString());
                    }
                } finally {
                    mediaPlayer.release();
                }
            }

            @Override
            public void failed() {
                Toast.makeText(context, "语音文件下载失败", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
