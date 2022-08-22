module ViteHelper
  # This module is a port of code in @vitejs/plugin-legacy. We need it because ruby vite_plugin_legacy
  # has ommited to implement this logic. Original code here:
  # https://github.com/vitejs/vite/blob/722f5148ea494cdc15379d3a98dca0751131ca22/packages/plugin-legacy/src/index.ts#L408-L532

  SAFARI_10_NO_MODULE_FIX = "!function(){var e=document,t=e.createElement('script');if(!('noModule'in t)&&'onbeforeload'in t){var n=!1;e.addEventListener('beforeload',(function(e){if(e.target===t)n=!0;else if(!e.target.hasAttribute('nomodule')||!n)return;e.preventDefault()}),!0),t.type='module',t.src='.',e.head.appendChild(t),t.remove()}}();"

  LEGACY_POLYFILL_ID = 'vite-legacy-polyfill'
  LEGACY_ENTRY_ID = 'vite-legacy-entry'
  SYSTEM_JS_INLINE_CODE = "document.querySelectorAll('script[data-legacy-entry]').forEach((e) => System.import(e.getAttribute('data-src')))"

  DETECT_MODERN_BROWSER_VARNAME = '__vite_is_modern_browser'
  DETECT_MODERN_BROWSER_CODE = "try{import.meta.url;import('_').catch(()=>1);}catch(e){}window.#{DETECT_MODERN_BROWSER_VARNAME}=true;"
  DYNAMIC_FALLBACK_INLINE_CODE = "!function(){if(window.#{DETECT_MODERN_BROWSER_VARNAME})return;console.warn('vite: loading legacy build because dynamic import or import.meta.url is unsupported, syntax error above should be ignored');var e=document.getElementById('#{LEGACY_POLYFILL_ID}'),n=document.createElement('script');n.src=e.src,n.onload=function(){#{SYSTEM_JS_INLINE_CODE}},document.body.appendChild(n)}();"

  def vite_legacy_javascript_tag(name, asset_type: :javascript)
    legacy_name = name.sub(/(\..+)|$/, '-legacy\1')
    src = vite_asset_path(legacy_name, type: :virtual)
    javascript_include_tag(src, nomodule: true, 'data-legacy-entry': true, 'data-src': src)
  end

  def vite_legacy_polyfill_tag
    safe_join [
      javascript_tag(SAFARI_10_NO_MODULE_FIX, type: :module, nonce: true),
      javascript_include_tag(vite_asset_path('legacy-polyfills', type: :virtual), nomodule: true, id: LEGACY_POLYFILL_ID)
    ]
  end

  def vite_legacy_fallback_tag
    safe_join [
      javascript_tag(DETECT_MODERN_BROWSER_CODE, type: :module, nonce: true),
      javascript_tag(DYNAMIC_FALLBACK_INLINE_CODE, type: :module, nonce: true)
    ]
  end
end
