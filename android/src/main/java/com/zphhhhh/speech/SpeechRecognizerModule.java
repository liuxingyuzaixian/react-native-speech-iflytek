package com.zphhhhh.speech;

import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.RequiresApi;

//import com.arthenica.mobileffmpeg.Config;
//import com.arthenica.mobileffmpeg.ExecuteCallback;
//import com.arthenica.mobileffmpeg.FFmpeg;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.IllegalViewOperationException;
import com.iflytek.cloud.ErrorCode;
import com.iflytek.cloud.RecognizerListener;
import com.iflytek.cloud.RecognizerResult;
import com.iflytek.cloud.SpeechConstant;
import com.iflytek.cloud.SpeechError;
import com.iflytek.cloud.SpeechRecognizer;
import com.iflytek.cloud.SpeechUtility;
import com.zphhhhh.speech.bean.SpeechResultBean;
import com.zphhhhh.speech.impl.DownloadCallback;
import com.zphhhhh.speech.impl.SuccessCallback;
import com.zphhhhh.speech.util.DeleteFileUtil;
import com.zphhhhh.speech.util.MediaPlayerManager;
import com.zphhhhh.speech.util.WavMergeUtil;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.annotation.Nullable;

import static com.zphhhhh.speech.util.Const.AppId;
import static java.lang.Thread.sleep;

public class SpeechRecognizerModule extends ReactContextBaseJavaModule {
    private Context context;

    private static SpeechRecognizer mIat;
    private static RecognizerListener mIatListener;

    private static long startTime;
    private static long endTime;
    int ret = 0; // 函数调用返回值
    private List<String> currentTextList = new ArrayList<>();
    private List<String> currentResultList = new ArrayList<>();
    private String oldVoicePath;

    public SpeechRecognizerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.context = reactContext;
    }

    @Override
    public String getName() {
        return "SpeechRecognizerModule";
    }

    @ReactMethod
    public void initialize() {
        if (mIat != null) {
            return;
        }

        SpeechUtility.createUtility(this.context, SpeechConstant.APPID + "=" + AppId);

        mIat = SpeechRecognizer.createRecognizer(this.context, null);
        mIatListener = new RecognizerListener() {
            @Override
            public void onVolumeChanged(int volume, byte[] bytes) {
                WritableMap params = Arguments.createMap();
                params.putInt("volume", volume);
                SpeechRecognizerModule.this.onJSEvent(getReactApplicationContext(), "onRecognizerVolumeChanged", params);
            }

            @Override
            public void onBeginOfSpeech() {
                Log.e("zhanglei", "onBeginOfSpeech");
            }

            @Override
            public void onEndOfSpeech() {
                Log.e("zhanglei", "onEndOfSpeech");
            }

            @Override
            public void onResult(RecognizerResult results, boolean isLast) {
                onIatResult(results, isLast);
                Log.e("zhanglei", "onResult" + isLast);
            }

            @Override
            public void onError(SpeechError error) {
                onIatError(error);
                Log.e("zhanglei", "error" + error.toString());
            }

            @Override
            public void onEvent(int i, int i1, int i2, Bundle bundle) {
                Log.e("zhanglei", "onEvent");
            }
        };
        setIatParam();
    }

    @ReactMethod
    public void start() {
        this.oldVoicePath = "";
        startTime = System.currentTimeMillis();

        if (mIat.isListening()) {
            mIat.cancel();
        }
        mIat.startListening(mIatListener);
        if (ret != ErrorCode.SUCCESS) {
            showTip("听写失败,错误码：" + ret + ",请点击网址https://www.xfyun.cn/document/error-code查询解决方案");
        } else {
//            showTip("请开始说话…");
        }
    }

    @ReactMethod
    public void startWithLastAudioPath(String oldVoicePath) {
        this.oldVoicePath = oldVoicePath;
        startTime = System.currentTimeMillis();

        if (mIat.isListening()) {
            mIat.cancel();
        }
        mIat.startListening(mIatListener);
        if (ret != ErrorCode.SUCCESS) {
            showTip("听写失败,错误码：" + ret + ",请点击网址https://www.xfyun.cn/document/error-code查询解决方案");
        } else {
//            showTip("请开始说话…");
        }
    }

    /**
     * 1，回调空字符串
     * 2，取消语音识别监听
     * 3，删除录音文件
     */
    @ReactMethod
    public void clear() {
        if (mIat.isListening()) {
            mIat.cancel();
        }
        DeleteFileUtil.delete(xunfeiTemp());
        DeleteFileUtil.delete(mergeTemp());
        DeleteFileUtil.delete(finalFile());

        currentResultList.clear();
    }

    /**
     * 取消本次语音识别
     */
    @ReactMethod
    public void cancel() {
        if (mIat.isListening()) {
            mIat.cancel();
        }
    }

    @ReactMethod
    public void isListening(Promise promise) {
        try {
            if (mIat.isListening()) {
                promise.resolve(true);
            } else {
                promise.resolve(false);
            }
        } catch (IllegalViewOperationException e) {
            promise.reject("Error: isListening()", e);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @ReactMethod
    public void stop() {
        if (mIat.isListening()) {
            mIat.stopListening();
        }
    }

    private void mergeVoiceFile(final SuccessCallback callback) {
        new Thread(new Runnable() {
            @RequiresApi(api = Build.VERSION_CODES.KITKAT)
            @Override
            public void run() {
                try {
                    sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                //处理之后的逻辑
                File finalFile = new File(finalFile());

                boolean isOldVoiceExist = oldVoicePath != null && !"".equals(oldVoicePath);

                if (isOldVoiceExist){
//                    if (oldVoicePath.endsWith(".m4a")){
//                        final String newFilePath=AndroidAudioConverterManager.getInstance().getConvertedFile(oldVoicePath);
//
//                        String transformCommand="-i "+oldVoicePath+" -y "+newFilePath;
//                        FFmpeg.executeAsync(transformCommand, new ExecuteCallback() {
//                            @Override
//                            public void apply(long executionId, int returnCode) {
//                                if (returnCode == 0) {
//
//                                    String concatCommand="-i "+newFilePath+" -i "+xunfeiTemp()+" -filter_complex '[0:0] [1:0] concat=n=2:v=0:a=1 [a]' -map [a] -y "+finalFile();
//                                    FFmpeg.executeAsync(concatCommand, new ExecuteCallback() {
//                                        @Override
//                                        public void apply(long executionId, int returnCode) {
//                                            if (returnCode == 0) {
//                                                Log.i(Config.TAG, "Command execution completed successfully. ===== executionId:" + executionId + "  returnCode:" + returnCode);
//                                                callback.success();
//                                            }
//                                        }
//                                    });
//                                }
//                            }
//                        });
//                    }else{
                        File[] files = new File[]{new File(oldVoicePath), new File(xunfeiTemp())};
                        WavMergeUtil.mergeWav(files, mergeTemp());
                        WavMergeUtil.copyFile(mergeTemp(), finalFile());
                        DeleteFileUtil.delete(mergeTemp());
                        callback.success();
//                    }
                }else if (finalFile.exists()){
                    File[] files = new File[]{new File(finalFile()), new File(xunfeiTemp())};

                    WavMergeUtil.mergeWav(files, mergeTemp());
                    WavMergeUtil.copyFile(mergeTemp(), finalFile());
                    DeleteFileUtil.delete(mergeTemp());
                    callback.success();
                }else{
                    if (!new File(xunfeiTemp()).exists()) {
                        return;
                    }
                    try {
                        finalFile.createNewFile();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    WavMergeUtil.copyFile(xunfeiTemp(), finalFile());
                    DeleteFileUtil.delete(xunfeiTemp());
                    callback.success();
                }
            }
        }).start();
    }

    @ReactMethod
    public void play(String path, Promise promise) {
        MediaPlayerManager.getInstance().play(path, context, promise);
    }

    @ReactMethod
    public void stopPlay() {
        MediaPlayerManager.getInstance().stopPlay();
    }

    @ReactMethod
    public void getVoiceDuration(String path, Promise promise) {
//        String path=context.getExternalFilesDir("") + "/wKgNSF_-poWAGLTjAAQt1DwlAF4667.wav";
        MediaPlayerManager.getInstance().getVoiceDuration(context, path, promise);
    }

    //讯飞语音合成存放路径
    private String xunfeiTemp() {
        return context.getExternalFilesDir("") + "/xunfeiTemp.wav";
    }

    //讯飞语音合成存放路径
    private String mergeTemp() {
        return context.getExternalFilesDir("") + "/temp.wav";
    }

    //最终生成的语音文件地址
    private String finalFile() {
        return context.getExternalFilesDir("") + "/SpeechRecognizer.wav";
    }

    //波形图文件
    private String voiceWaveTemp() {
        return context.getExternalCacheDir() + "/voiceWaveTemp.wav";
    }

    @ReactMethod
    public void setParameter(String parameter, String value) {
        if (parameter.equals(SpeechConstant.ASR_AUDIO_PATH)) {
            value = Environment.getExternalStorageDirectory() + value;
        }
        mIat.setParameter(parameter, value);
    }

    @ReactMethod
    public void getParameter(String param, Promise promise) {
        String value = mIat.getParameter(param);
        try {
            promise.resolve(value);
        } catch (IllegalViewOperationException e) {
            promise.reject("Error: getParameter()", e);
        }
    }

    private void setIatParam() {
        // 清空参数
//        mIat.setParameter(SpeechConstantModule.PARAMS, null);
        mIat.setParameter(SpeechConstant.PARAMS, null);

        // 设置听写引擎
        mIat.setParameter(SpeechConstant.ENGINE_TYPE, SpeechConstant.TYPE_CLOUD);

        // 设置返回结果格式
        mIat.setParameter(SpeechConstant.RESULT_TYPE, "json");

        // 设置语言
        mIat.setParameter(SpeechConstant.LANGUAGE, "zh_cn");
        // 设置语言区域
        mIat.setParameter(SpeechConstant.ACCENT, "mandarin");

        // 设置语音前端点:静音超时时间，即用户多长时间不说话则当做超时处理
        mIat.setParameter(SpeechConstant.VAD_BOS, "10000");

        // 设置语音后端点:后端点静音检测时间，即用户停止说话多长时间内即认为不再输入， 自动停止录音
        mIat.setParameter(SpeechConstant.VAD_EOS, "10000");

        //一次语音最大时长
        mIat.setParameter(SpeechConstant.KEY_SPEECH_TIMEOUT, "60000");

        // 设置标点符号,设置为"0"返回结果无标点,设置为"1"返回结果有标点
        mIat.setParameter(SpeechConstant.ASR_PTT, "1");

        //[动态修正](https://www.xfyun.cn/doc/asr/voicedictation/Android-SDK.html#_3%E3%80%81%E5%8F%82%E6%95%B0%E8%AF%B4%E6%98%8E)
        mIat.setParameter("dwa", "wpgs");

        // 设置音频保存路径，保存音频格式支持pcm、wav，设置路径为sd卡请注意WRITE_EXTERNAL_STORAGE权限
        // 注：AUDIO_FORMAT参数语记需要更新版本才能生效
        mIat.setParameter(SpeechConstant.AUDIO_FORMAT, "wav");
        mIat.setParameter(SpeechConstant.ASR_AUDIO_PATH, xunfeiTemp());
    }

    private static SpeechResultBean parseIatResult(String json) {
        StringBuilder ret = new StringBuilder();
        boolean isModify = false;
        try {
            JSONTokener tokener = new JSONTokener(json);
            JSONObject joResult = new JSONObject(tokener);
            JSONArray words = joResult.getJSONArray("ws");
            //pgs中apd为新增,rpl为替换
            String pgs = joResult.getString("pgs");
            /**
             * 判断是否修改
             */
            isModify = "rpl".equals(pgs);
            for (int i = 0; i < words.length(); i++) {
                // 转写结果词，默认使用第一个结果
                JSONArray items = words.getJSONObject(i).getJSONArray("cw");
                JSONObject obj = items.getJSONObject(0);
                ret.append(obj.getString("w"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new SpeechResultBean(isModify, ret.toString());
    }

    //遍历列表获取字符串
    private String getText(List<String> list) {
        String text = "";
        for (int i = 0; i < list.size(); i++) {
            text += list.get(i);
        }
        return text;
    }

    private void onIatResult(RecognizerResult results, boolean isLast) {
//        Log.e("zhanglei-results:", results.getResultString());
        SpeechResultBean temp = parseIatResult(results.getResultString());
        if (temp.isModify()) {
            //移除上一个
            if (currentTextList.size() > 0) {
                currentTextList.remove(currentTextList.size() - 1);
            }
            if (currentResultList.size() > 0) {
                currentResultList.remove(currentResultList.size() - 1);
            }
        }
        currentTextList.add(temp.getText());
        currentResultList.add(temp.getText());

        final String text = getText(currentTextList);
        final String[] result = {getText(currentResultList)};
        /**
         * 有些手机合成速度较慢，这里会再次回调
         */
        if (isLast) {
            mergeVoiceFile(new SuccessCallback() {
                @Override
                public void success() {
                    result[0] += text;
                    //文件合成还未结束
                    onJSEvent(text, result[0], true);
                    currentTextList.clear();
                }
            });
        } else {
            onJSEvent(text, result[0], false);
        }
    }

    private void onJSEvent(String text, String result, boolean isLast) {
        endTime = System.currentTimeMillis();
        int duration = (int) (endTime - startTime);

        WritableMap params = Arguments.createMap();

        params.putString("text", text);
        params.putString("result", result);
        params.putBoolean("isLast", isLast);
        params.putInt("duration", duration);
        if (isLast) {
            params.putString("audioPath", getAudioPath());
        }

        this.onJSEvent(getReactApplicationContext(), "onRecognizerResult", params);
    }

    //有限取生成文件，没有则取波形图，再没有返回空字符串
    private String getAudioPath() {
        File finalFile = new File(finalFile());
        File voiceWaveTemp = new File(voiceWaveTemp());
        if (finalFile.exists() && finalFile.length() > 10) {
            return finalFile();
        } else if (voiceWaveTemp.exists() && voiceWaveTemp.length() > 10) {
            return voiceWaveTemp();
        } else {
            return "";
        }
    }

    private void onIatError(SpeechError error) {
        WritableMap params = Arguments.createMap();

        params.putInt("errorCode", error.getErrorCode());
        params.putString("message", error.getErrorDescription());
        params.putString("plainDescription", error.getPlainDescription(true));

        this.onJSEvent(getReactApplicationContext(), "onRecognizerError", params);
    }

    private void showTip(final String str) {
        Toast.makeText(this.context, str, Toast.LENGTH_SHORT).show();
    }

    private void onJSEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }
}
