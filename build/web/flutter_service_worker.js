'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "f819eac9937fed063715fb9a46b024be",
"version.json": "f0911f0e63f6a5757f4c7a02e78a90d3",
"index.html": "3e8b9886d0b64daf25f203790be629e8",
"/": "3e8b9886d0b64daf25f203790be629e8",
"main.dart.js": "3afe2e594524f6ae4952196b975f28e7",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "05681a71fe2a8782d083eec8bec69761",
"assets/AssetManifest.json": "5ce84777700901013b55110909e37954",
"assets/NOTICES": "f90da8183ac0cd578c84a43b7d5fbec4",
"assets/FontManifest.json": "1031a1db63b0247eb065faa27bfb7b0e",
"assets/AssetManifest.bin.json": "42bb5ac970bd95cd37c93f9d566ca8a2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "2c328dbf5b46d614c16d84ac0b87b6a7",
"assets/fonts/MaterialIcons-Regular.otf": "40d70c76de3aa21614c413958a77c107",
"assets/assets/fonts/NotoSans_SemiCondensed-LightItalic.ttf": "6cb7c1ce595bf603a5bcdd29674fbe93",
"assets/assets/fonts/NotoSans_SemiCondensed-BoldItalic.ttf": "ea5e5821986ae65f7ac5c8fe83db5f3a",
"assets/assets/fonts/NotoSans_ExtraCondensed-BoldItalic.ttf": "a44354a75ba81a9b2576645c2b611103",
"assets/assets/fonts/NotoSans_ExtraCondensed-SemiBold.ttf": "543477dce7588498b66d59f2b43b9743",
"assets/assets/fonts/NotoSans_ExtraCondensed-SemiBoldItalic.ttf": "e7e3c1cfa9823d4b2cbfbbf502cd5ad7",
"assets/assets/fonts/NotoSans-Regular.ttf": "f46b08cc90d994b34b647ae24c46d504",
"assets/assets/fonts/NotoSans_SemiCondensed-Medium.ttf": "482bc84b30d8a67e6ea1a4dfd200754d",
"assets/assets/fonts/NotoSans_ExtraCondensed-BlackItalic.ttf": "e640c9c3a4663f493b2cfd849cedb725",
"assets/assets/fonts/NotoSans_ExtraCondensed-ExtraLight.ttf": "257bddc4dd9e1d978d3b7208a5905b3a",
"assets/assets/fonts/NotoSans_SemiCondensed-ExtraLight.ttf": "c8deffd4b06ac3c3e9ded98cbc90162f",
"assets/assets/fonts/NotoSans_SemiCondensed-ThinItalic.ttf": "59f0e5a1d84fa023adb49353d1c3673e",
"assets/assets/fonts/NotoSans_ExtraCondensed-Bold.ttf": "111d55305a99e9cec782701c7c6cc74a",
"assets/assets/fonts/NotoSans_Condensed-MediumItalic.ttf": "d8e5c10cd5bd8e1f0919efe7ef6bc65b",
"assets/assets/fonts/NotoSans_ExtraCondensed-ThinItalic.ttf": "27037a54fba86f2b0bbd0443cf389ed6",
"assets/assets/fonts/NotoSans_Condensed-Italic.ttf": "398f5e4adcc17cc17c9ab05948447e2b",
"assets/assets/fonts/NotoSans_ExtraCondensed-ExtraBold.ttf": "8c124fbab5a782c2743339469047fead",
"assets/assets/fonts/NotoSans_SemiCondensed-Black.ttf": "4f882d6d6e88aa949424b583612b1fab",
"assets/assets/fonts/NotoSans_ExtraCondensed-Thin.ttf": "324f53bca3dcac0b5157771ccedc2b27",
"assets/assets/fonts/NotoSans_SemiCondensed-SemiBoldItalic.ttf": "042500be97400c7eef4537b0b993fbd6",
"assets/assets/fonts/NotoSans-Medium.ttf": "a1311858ffd88b69aa5eadafd8f5c164",
"assets/assets/fonts/NotoSans_Condensed-Regular.ttf": "64fc8913b2e7502931b7154aafa04124",
"assets/assets/fonts/NotoSans_Condensed-LightItalic.ttf": "15b6943bf4be6f831ff5c6a6215da45a",
"assets/assets/fonts/NotoSans_ExtraCondensed-Light.ttf": "9902a62a5973ed74641cb5384c3339a1",
"assets/assets/fonts/NotoSans_SemiCondensed-ExtraBoldItalic.ttf": "2f4d0e4942d108826d82296592a14b85",
"assets/assets/fonts/NotoSans_Condensed-ExtraLightItalic.ttf": "2c715c571218e58293e37786652ff8ab",
"assets/assets/fonts/NotoSans_ExtraCondensed-MediumItalic.ttf": "8d3fe633391d72858140c8c254d07e12",
"assets/assets/fonts/NotoSans_Condensed-BlackItalic.ttf": "62a5aafc50d2074312707785a6e83242",
"assets/assets/fonts/NotoSans-MediumItalic.ttf": "c3df9f63939ae47a3f978d3fdfd8ed8b",
"assets/assets/fonts/NotoSans_Condensed-ExtraBoldItalic.ttf": "f8f5e34f2d3d2b7d96e9448f55440644",
"assets/assets/fonts/NotoSans_Condensed-Bold.ttf": "2491ed6bf1ddac68c6ede5177d4c9ee1",
"assets/assets/fonts/NotoSans-Black.ttf": "a45b4647b217a27f7eb0db1f4a4a2421",
"assets/assets/fonts/NotoSans-Bold.ttf": "2ea5e0855d5a3ec3f561b5bc62b39805",
"assets/assets/fonts/NotoSans-Thin.ttf": "52d74c81e361a9c83871d47fe86a3c59",
"assets/assets/fonts/NotoSans_SemiCondensed-Regular.ttf": "cf37ab7c1275cd77066ffdab71761a08",
"assets/assets/fonts/NotoSans_Condensed-Thin.ttf": "1d1a8879f9215d761ff053b1f7b6bce4",
"assets/assets/fonts/NotoSans_SemiCondensed-BlackItalic.ttf": "329e174b82d6ca7290f616680c380fa8",
"assets/assets/fonts/NotoSans_ExtraCondensed-Medium.ttf": "f6a266953128b72057342818990ee901",
"assets/assets/fonts/NotoSans_ExtraCondensed-LightItalic.ttf": "602f6698f95d4b33c2af73be60107913",
"assets/assets/fonts/NotoSans_Condensed-Light.ttf": "6e48b669c8c2447a8bdf3e10b085dcfb",
"assets/assets/fonts/NotoSans_ExtraCondensed-ExtraLightItalic.ttf": "17e5ca0add975465482077aac44527cb",
"assets/assets/fonts/NotoSans_SemiCondensed-SemiBold.ttf": "8aad5697ec74d04935d7303d028c0924",
"assets/assets/fonts/NotoSans_Condensed-Black.ttf": "67eeb10b62b1b695e8e6a63c7c2b64f5",
"assets/assets/fonts/NotoSans-SemiBold.ttf": "f5a1e1476234ba356911d9b4e287e30d",
"assets/assets/fonts/NotoSans_ExtraCondensed-ExtraBoldItalic.ttf": "e51470984914535b7677d3f3d9198b30",
"assets/assets/fonts/NotoSans_Condensed-SemiBoldItalic.ttf": "5f552e38f26c02467c5c9405d8ac9f6b",
"assets/assets/fonts/NotoSans-SemiBoldItalic.ttf": "69f9af3b328aa8557b3c81df5ccaece6",
"assets/assets/fonts/NotoSans-LightItalic.ttf": "df8dedaaf9c464305f57eaad5d2a30f3",
"assets/assets/fonts/NotoSans_ExtraCondensed-Regular.ttf": "1fb7bb12d7bc705ab5068bc47b4f2d51",
"assets/assets/fonts/NotoSans-Light.ttf": "1e81ec98e0668cbee241a1f0a0ab90ad",
"assets/assets/fonts/NotoSans_ExtraCondensed-Italic.ttf": "573c1be9a2d7375cd229b7aff3c60dcc",
"assets/assets/fonts/NotoSans-BoldItalic.ttf": "4321108b0cf255575499e2361b6501e0",
"assets/assets/fonts/NotoSans_Condensed-SemiBold.ttf": "aac8d24fa62d5ff3f064225aed71c7b6",
"assets/assets/fonts/NotoSans_Condensed-ExtraBold.ttf": "311ac2ee7d6cd65242786012c10b5a79",
"assets/assets/fonts/NotoSans_Condensed-Medium.ttf": "397c9a824d11bcd7d964a9ab2cc76b2f",
"assets/assets/fonts/NotoSans-BlackItalic.ttf": "13ac991d429a2ca6be9451e38a5079cd",
"assets/assets/fonts/NotoSans_SemiCondensed-Light.ttf": "2b0357a0ed19c7aa906067c7c04aef6a",
"assets/assets/fonts/NotoSans-ExtraBoldItalic.ttf": "cb45ddbeb7ca5b0c1934ce48f8a3767b",
"assets/assets/fonts/NotoSans_ExtraCondensed-Black.ttf": "7d5e306fbe806f491fbb845303acba18",
"assets/assets/fonts/NotoSans_SemiCondensed-Bold.ttf": "29978a48002f8d63548e5cec9bd1e4c1",
"assets/assets/fonts/NotoSans-ExtraLight.ttf": "b4dcd4a644afea0c03cc0aacd66105eb",
"assets/assets/fonts/NotoSans_SemiCondensed-ExtraBold.ttf": "1df247aaaad1ae7b4129108087425a2c",
"assets/assets/fonts/NotoSans-ThinItalic.ttf": "a16fd39654ea16dc249af4623b1e05cb",
"assets/assets/fonts/NotoSans_SemiCondensed-Italic.ttf": "f684b23b3aff5afcb0087c7b1d6e66e9",
"assets/assets/fonts/NotoSans_SemiCondensed-MediumItalic.ttf": "0bd36ada9682d32ed09a42b6f9830cf1",
"assets/assets/fonts/NotoSans-ExtraLightItalic.ttf": "e7842c55efb8a16943eabe63ad94a93b",
"assets/assets/fonts/NotoSans_Condensed-BoldItalic.ttf": "f4f6b6e183581f8220e3a6c201a67162",
"assets/assets/fonts/NotoSans_SemiCondensed-Thin.ttf": "e06d20d679f09b849b04e109b599d01c",
"assets/assets/fonts/NotoSans_SemiCondensed-ExtraLightItalic.ttf": "e10b31532ef04ada3c3137f22944fc14",
"assets/assets/fonts/NotoSans_Condensed-ExtraLight.ttf": "f173909675f4c4d17b22e42e44048a2d",
"assets/assets/fonts/NotoSans-ExtraBold.ttf": "6d20a0d666df4e4ed72c2f666a974ea0",
"assets/assets/fonts/NotoSans_Condensed-ThinItalic.ttf": "985a2450d66044c1186e46f2ce26a031",
"assets/assets/fonts/NotoSans-Italic.ttf": "a6d070775dd5e6bfff61870528c6248a",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
