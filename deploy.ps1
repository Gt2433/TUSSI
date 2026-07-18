$cli = "./firebase.exe"
$flutterPath = "C:\src\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterPath)) {
    $flutterPath = "flutter"
}

# 1. Process New Logo if present
$newLogoDir = Join-Path $PSScriptRoot "New logo"
if (Test-Path $newLogoDir) {
    Write-Host "Processing new logo..."
    $imageFile = Get-ChildItem $newLogoDir | Where-Object { $_.Extension -in ".png", ".jpg", ".jpeg" } | Select-Object -First 1
    if ($imageFile) {
        Copy-Item $imageFile.FullName "./icon.png" -Force
        Copy-Item $imageFile.FullName "web/icons/Icon-192.png" -Force
        Copy-Item $imageFile.FullName "web/icons/Icon-512.png" -Force
        Copy-Item $imageFile.FullName "web/icons/Icon-maskable-192.png" -Force
        Copy-Item $imageFile.FullName "web/icons/Icon-maskable-512.png" -Force
        Copy-Item $imageFile.FullName "web/favicon.png" -Force
        Remove-Item $newLogoDir -Recurse -Force
        Write-Host "New logo processed and folder removed."
    }
}

# 2. Generate Icons
Write-Host "Generating launcher icons..."
& $flutterPath pub run flutter_launcher_icons

# 3. Build Web App
Write-Host "Building web app..."
& $flutterPath build web --release --pwa-strategy=none

# Overwrite flutter_service_worker.js with self-destructive version to update existing clients
Write-Host "Creating self-destructive service worker..."
$swCode = @"
self.addEventListener('install', (event) => {
  self.skipWaiting();
});
self.addEventListener('activate', (event) => {
  event.waitUntil(
    self.clients.claim().then(() => {
      return self.registration.unregister();
    }).then(() => {
      return self.clients.matchAll();
    }).then((clients) => {
      clients.forEach((client) => {
        if (client.url && typeof client.navigate === 'function') {
          client.navigate(client.url);
        }
      });
    })
  );
});
"@
[System.IO.File]::WriteAllText("build/web/flutter_service_worker.js", $swCode)

# 4. Check/Download Firebase CLI
if (-not (Test-Path $cli)) {
    Write-Host "Downloading Firebase CLI..."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri "https://firebase.tools/bin/win/latest" -OutFile $cli
}

# 5. Login & Deploy
Write-Host "Logging in to Firebase..."
& $cli login
Write-Host "Deploying to Firebase Hosting..."
& $cli deploy --only hosting
Write-Host "Deploy complete!"
