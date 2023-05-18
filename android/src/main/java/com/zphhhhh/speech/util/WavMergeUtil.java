package com.zphhhhh.speech.util;

import android.os.Build;

import androidx.annotation.RequiresApi;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * 获取wav头文件然后合并成单个wav
 *
 * @author zcf
 * @date 2017-10-17
 */
public class WavMergeUtil {
    /**
     * meger多个wav
     *
     * @param inputs 多个wav
     * @param output 要生成的wav
     * @throws IOException
     */
    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    public static void mergeWav(File[] inputs, String output) {
        if (inputs.length < 1) {
            return;
        }
        try (FileInputStream fis = new FileInputStream(inputs[0]);
             FileOutputStream fos = new FileOutputStream(new File(output))) {
            byte[] buffer = new byte[1024 * 4];
            int total = 0;
            int count;
            while ((count = fis.read(buffer)) > -1) {
                fos.write(buffer, 0, count);
                total += count;
            }
            fis.close();
            for (int i = 1; i < inputs.length; i++) {
                File file = inputs[i];
                try (FileInputStream fisH = new FileInputStream(file)) {
                    Header header = resolveHeader(fisH);
                    FileInputStream dataInputStream = header.dataInputStream;
                    while ((count = dataInputStream.read(buffer)) > -1) {
                        fos.write(buffer, 0, count);
                        total += count;
                    }
                }
            }
            fos.flush();
            fos.close();
            FileInputStream fisHo = new FileInputStream(new File(output));
            Header outputHeader = resolveHeader(fisHo);
            outputHeader.dataInputStream.close();
            try (RandomAccessFile res = new RandomAccessFile(output, "rw")) {
                res.seek(4);
                byte[] fileLen = intToByteArray(total + outputHeader.dataOffset - 8);
                res.write(fileLen, 0, 4);
                res.seek(outputHeader.dataSizeOffset);
                byte[] dataLen = intToByteArray(total);
                res.write(dataLen, 0, 4);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 解析头部，并获得文件指针指向数据开始位置的InputStreram，记得使用后需要关闭
     */
    private static Header resolveHeader(FileInputStream fis) throws IOException {
        byte[] byte4 = new byte[4];
        byte[] buffer = new byte[2048];
        int readCount = 0;
        Header header = new Header();
        fis.read(byte4);// RIFF
        fis.read(byte4);
        readCount += 8;
        header.fileSizeOffset = 4;
        header.fileSize = byteArrayToInt(byte4);
        fis.read(byte4);// WAVE
        fis.read(byte4);// fmt
        fis.read(byte4);
        readCount += 12;
        int fmtLen = byteArrayToInt(byte4);
        fis.read(buffer, 0, fmtLen);
        readCount += fmtLen;
        fis.read(byte4);// data or fact
        readCount += 4;
        if (isFmt(byte4, 0)) {// 包含fmt段
            fis.read(byte4);
            int factLen = byteArrayToInt(byte4);
            fis.read(buffer, 0, factLen);
            fis.read(byte4);// data
            readCount += 8 + factLen;
        }
        fis.read(byte4);// data size
        int dataLen = byteArrayToInt(byte4);
        header.dataSize = dataLen;
        header.dataSizeOffset = readCount;
        readCount += 4;
        header.dataOffset = readCount;
        header.dataInputStream = fis;
        return header;
    }

    private static boolean isFmt(byte[] bytes, int start) {
        if (bytes[start + 0] == 'f' && bytes[start + 1] == 'm' && bytes[start + 2] == 't' && bytes[start + 3] == ' ') {
            return true;
        } else {
            return false;
        }
    }

    /**
     * 将int转化为byte[]
     */
    private static byte[] intToByteArray(int data) {
        return ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(data).array();
    }

    /**
     * 将byte[]转化为int
     */
    private static int byteArrayToInt(byte[] b) {
        return ByteBuffer.wrap(b).order(ByteOrder.LITTLE_ENDIAN).getInt();
    }

    public static void copyFile(String source, String dest) {
        InputStream input = null;
        OutputStream output = null;
        try {
            input = new FileInputStream(new File(source));
            output = new FileOutputStream(new File(dest));
            byte[] buf = new byte[1024];
            int bytesRead;
            while ((bytesRead = input.read(buf)) > 0) {
                output.write(buf, 0, bytesRead);
            }
            input.close();
            output.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 头部部分信息
     */
    static class Header {
        public int fileSize;
        public int fileSizeOffset;
        public int dataSize;
        public int dataSizeOffset;
        public int dataOffset;
        public FileInputStream dataInputStream;
    }
}

