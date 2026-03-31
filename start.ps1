# start.ps1
Clear-Host

# =========================================================
# 🛠️ CONFIGURACIÓN DEL PROYECTO
# =========================================================
$APP_NAME           = "Flutter Entrevista't"
$DEV_CONTAINER_NAME = "flutter_hot_reload" # Debe coincidir con el container_name de docker-compose-dev.yml
$LOCAL_PORT         = "8080"
$FLUTTER_VERSION    = "3.27.1" # Cambia esto si el nuevo proyecto usa otra versión
$MAIN_ENV_VAR       = "API_URL" # La variable clave que necesitas inyectar en el build

$ComposeDev   = "docker-compose-dev.yml"
$ComposeProd  = "docker-compose.yml"
$ComposeBuild = "docker-compose-build.yml"
# =========================================================

# --- FUNCIÓN DE COMPROBACIÓN ---
function Test-Docker {
    Write-Host "Verifying Docker Engine..." -ForegroundColor DarkGray
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[CRITICAL ERROR] Docker is not running." -ForegroundColor Red
        Write-Host "> Please open 'Docker Desktop' and wait for it to start." -ForegroundColor Yellow
        Write-Host "> Press Enter to exit..."
        Read-Host
        exit
    }
}

Test-Docker

Write-Host "$APP_NAME - Docker Manager" -ForegroundColor Cyan

while ($true) {
    Write-Host "`n----------------------------------------" -ForegroundColor Green
    Write-Host "CONTROL MENU" -ForegroundColor Green
    Write-Host "----------------------------------------"
    Write-Host "1. Run DEV Mode (Interactive - Press 'R' to reload)"
    Write-Host "2. Run PROD Mode (Nginx Preview)"
    Write-Host "3. View Live Logs (Auto-detect)"
    Write-Host "4. Stop ALL Containers"
    Write-Host "5. Run Tests"
    Write-Host "6. Build Android APK (Release)" 
    Write-Host "7. Generate App Icons"
    Write-Host "8. Exit"
    Write-Host "----------------------------------------"
    
    $selection = Read-Host "Select option"

    if ($selection -eq "1") {
        Write-Host "Switching to DEV Mode..." -ForegroundColor Yellow
        docker-compose -f $ComposeProd down 2>$null

        Write-Host "Building DockerfileDev..." -ForegroundColor Cyan
        docker-compose -f $ComposeDev up -d --build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Dev Server started." -ForegroundColor Green
            try { Start-Process "http://localhost:$LOCAL_PORT" } catch {}
            
            Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
            Write-Host "ENTERING INTERACTIVE MODE" -ForegroundColor Yellow
            Write-Host "Press 'R' (Shift+r) to Hot Restart." -ForegroundColor Cyan
            Write-Host "Press 'Ctrl + C' to stop the container and return to menu." -ForegroundColor Red
            Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow
            
            Start-Sleep -Seconds 2
            # Usamos la variable para atarnos al contenedor correcto
            docker attach $DEV_CONTAINER_NAME
        } else {
            Write-Host "`n[ERROR] Failed to start Dev Server." -ForegroundColor Red
        }
    }
    elseif ($selection -eq "2") {
        Write-Host "Switching to PROD Mode..." -ForegroundColor Yellow
        docker-compose -f $ComposeDev down 2>$null

        Write-Host "Building DockerfileProd & Nginx..." -ForegroundColor Cyan
        docker-compose -f $ComposeProd up -d --build
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n[SUCCESS] Production Preview running at http://localhost:$LOCAL_PORT" -ForegroundColor Green
            try { Start-Process "http://localhost:$LOCAL_PORT" } catch {}
        } else {
            Write-Host "`n[ERROR] Failed to start Prod Server." -ForegroundColor Red
        }
    }
    elseif ($selection -eq "3") {
        Write-Host "Detecting active containers..." -ForegroundColor Yellow
        
        $devRunning = (docker-compose -f $ComposeDev ps -q)
        if ($devRunning) {
            Write-Host "Attaching to DEV container $DEV_CONTAINER_NAME... (Press Ctrl+C to detach/stop)" -ForegroundColor Cyan
            docker attach $DEV_CONTAINER_NAME
        }
        else {
            $prodRunning = (docker-compose -f $ComposeProd ps -q)
            if ($prodRunning) {
                Write-Host "Streaming PROD logs... (Ctrl+C to exit)" -ForegroundColor Cyan
                docker-compose -f $ComposeProd logs -f
            } else {
                Write-Host "[ERROR] No active containers found." -ForegroundColor Red
            }
        }
    }
    elseif ($selection -eq "4") {
        Write-Host "Stopping EVERYTHING..." -ForegroundColor Magenta
        docker-compose -f $ComposeDev down
        docker-compose -f $ComposeProd down
        docker-compose -f $ComposeBuild down 2>$null
        Write-Host "All clean." -ForegroundColor Green
    }
    elseif ($selection -eq "5") {
        $workdir = (Get-Location).Path
        Write-Host "Running flutter tests inside container..." -ForegroundColor Cyan
        # Usamos la variable de versión de Flutter
        docker run --rm -v "${workdir}:/app" -w /app ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} bash -lc "flutter pub get && flutter test"
    }
    elseif ($selection -eq "6") {
        Write-Host "Building Android APK (Release)..." -ForegroundColor Cyan
        
        $envPath = ".env"
        $envValue = $null

        if (Test-Path $envPath) {
            # Usamos la variable en lugar de buscar "API_URL" a fuego
            $line = Get-Content $envPath | Where-Object { $_ -match "^${MAIN_ENV_VAR}=" } | Select-Object -First 1
            
            if ($line) {
                $envValue = $line.Split("=", 2)[1].Trim().Trim('"').Trim("'")
                Write-Host "Creating build using $MAIN_ENV_VAR from .env:" -ForegroundColor DarkGray
                Write-Host " -> $envValue" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Variable '$MAIN_ENV_VAR' not found inside .env file." -ForegroundColor Red
                continue 
            }
        } else {
            Write-Host "[ERROR] .env file not found in current directory." -ForegroundColor Red
            continue
        }

        # Inyectamos la variable de forma dinámica
        docker-compose -f $ComposeBuild run --rm builder bash -c "flutter clean && flutter pub get && flutter build apk --release --dart-define=${MAIN_ENV_VAR}=$envValue"

        if ($LASTEXITCODE -eq 0) {
            $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
            if (Test-Path $apkPath) {
                Write-Host "`n[SUCCESS] APK generated successfully!" -ForegroundColor Green
                Write-Host "Location: $apkPath" -ForegroundColor Yellow
                Invoke-Item (Split-Path $apkPath)
            } else {
                Write-Host "[WARNING] Build finished but APK not found." -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERROR] Build failed." -ForegroundColor Red
        }
    } 
    elseif ($selection -eq "7") {
        Write-Host "Generating App Icons..." -ForegroundColor Cyan
        docker-compose -f $ComposeBuild run --rm builder bash -c "flutter pub get && dart run flutter_launcher_icons"
        Write-Host "Done! Check android/app/src/main/res/ to verify." -ForegroundColor Green
    }
    elseif ($selection -eq "8") {
        Write-Host "Stopping and Exiting..."
        docker-compose -f $ComposeDev down 2>$null
        docker-compose -f $ComposeProd down 2>$null
        exit
    } else {
        Write-Host "Invalid option." -ForegroundColor Red
    }
}