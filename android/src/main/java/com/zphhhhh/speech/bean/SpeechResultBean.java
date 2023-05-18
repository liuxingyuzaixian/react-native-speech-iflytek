package com.zphhhhh.speech.bean;

public class SpeechResultBean {
    private boolean isModify;
    private String text;

    public SpeechResultBean(boolean isModify, String text) {
        this.isModify = isModify;
        this.text = text;
    }

    public boolean isModify() {
        return isModify;
    }

    public void setModify(boolean modify) {
        isModify = modify;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }
}
