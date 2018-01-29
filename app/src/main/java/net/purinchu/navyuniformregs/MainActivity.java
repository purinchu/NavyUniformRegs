package net.purinchu.navyuniformregs;

import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class MainActivity extends AppCompatActivity {
    public static final String EXTRA_MESSAGE = "net.purinchu.navyuniformregs.MSG";
    private static final int HTML_BUF_SIZE = 16384;
    private static final String TAG = "main_act";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);
        WebView webView = findViewById(R.id.webView);

        // Some kind of web view client is required to make the widget
        // actually follow hyperlinks.
        webView.setWebViewClient(new WebViewClient());
        WebSettings webSettings = webView.getSettings();
        webSettings.setBuiltInZoomControls(true);
        webSettings.setDisplayZoomControls(false);

            /*
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
                Uri uri = Uri.parse(url);
                Log.d(TAG, "Loading " + url);
                try {
                    // getPath() includes the slash we need
                    String htmlPath = "compiled-regs" + uri.getPath();
                    WebResourceResponse resp;
                    InputStream htmlStream = loadHtmlStream(htmlPath);
                    Log.d(TAG, "Loading path " + htmlPath);
                    resp = new WebResourceResponse("text/html", "utf-8", htmlStream);
                    return resp;
                }
                catch(IOException e) {
                    Log.e(TAG, "Exception thrown reading file", e);
                    return super.shouldInterceptRequest(view, url);
                }
            }
        });
            */
        goHome(webView);
    }

    private void loadHtml(WebView webView, String htmlName)
    {
        try {
            InputStream htmlIn = loadHtmlStream(htmlName);
            ByteArrayOutputStream outBS = new ByteArrayOutputStream(HTML_BUF_SIZE);
            byte [] buffer = new byte [HTML_BUF_SIZE];

            while (htmlIn.read(buffer) != -1) {
                outBS.write(buffer);
            }

            String result = outBS.toString();
            webView.loadDataWithBaseURL(
                    "file:///android_asset/compiled-regs/Pages/default.aspx.html",
                    result, "text/html", "utf-8", "");
        }
        catch(IOException e) {
            webView.loadData("<h3>Couldn't load data!</h3>", "text/html", "utf-8");
        }
    }

    @Override
    public void onBackPressed() {
        WebView webView = findViewById(R.id.webView);
        if (webView.canGoBack()) {
            webView.goBack();
        }
        else {
            super.onBackPressed();
        }
    }

    private InputStream loadHtmlStream(String htmlName) throws IOException {
        return getAssets().open(htmlName, AssetManager.ACCESS_BUFFER);
    }

    @SuppressWarnings("unused")
    public void goHome(View view) {
        WebView webView = findViewById(R.id.webView);
        loadHtml(webView, "compiled-regs/Pages/default.aspx.html");
    }
}
