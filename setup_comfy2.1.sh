#!/bin/bash
# Скрипт остановится, если любая команда завершится с неисправимой ошибкой.
set -e

echo "--- Начало установки ComfyUI (v9.4, Финальная логически верная версия) ---"

# --- УМНАЯ ФУНКЦИЯ СКАЧИВАНИЯ С ЭКСПОНЕНЦИАЛЬНЫМ ОТКАТОМ ---
download_with_retries() {
    local url="$1"
    local output_path="$2"
    
    local attempts=0
    local max_attempts=6
    local success=false
    local base_wait_time=60

    echo "Скачиваю $url в $output_path..."
    while [ $attempts -lt $max_attempts ] && [ "$success" = false ]; do
        attempts=$((attempts+1))
        
        local exit_code=0
        
        if [[ "$url" == *"civitai.com"* ]]; then
            curl -L --continue-at - --connect-timeout 60 \
                 -H "Authorization: Bearer a9c46d86669d13a7d9f8826cedb9a3c5" \
                 "$url" -o "$output_path" || exit_code=$?
        else
            wget -c -T 60 "$url" -O "$output_path" || exit_code=$?
        fi

        if [ $exit_code -eq 0 ]; then
            echo "Файл успешно скачан."
            success=true
            sleep 5 
        else
            if [ $attempts -lt $max_attempts ]; then
                local wait_time=$((base_wait_time * (2 ** (attempts - 1))))
                local jitter=$(shuf -i 0-30 -n 1)
                local total_wait=$((wait_time + jitter))

                echo "Ошибка скачивания (код: $exit_code). Попытка $attempts из $max_attempts."
                echo "Включаю прогрессивный откат. Следующая попытка через $total_wait секунд..."
                sleep $total_wait
            else
                echo "КРИТИЧЕСКАЯ ОШИБКА: не удалось скачать файл '$url' после $max_attempts попыток."
                exit 1
            fi
        fi
    done
}
# --- КОНЕЦ ФУНКЦИИ ---

# --- БЛОКИ 1-4: УСТАНОВКА (остаются без изменений) ---
# --- 1. Подготовка системы ---
cd /workspace
if [ -d "ComfyUI" ]; then rm -rf ComfyUI; fi
apt-get update && apt-get install -y git p7zip-full build-essential
pkill -f caddy || true

# --- 2. Установка ComfyUI и базовых зависимостей ---
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install --upgrade pip
pip install -r requirements.txt
cd custom_nodes

# --- 3. Установка всех кастомных узлов ---
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack; pip install -r ComfyUI-Impact-Pack/requirements.txt
git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack ComfyUI-Impact-Pack/impact_subpack; pip install -r ComfyUI-Impact-Pack/impact_subpack/requirements.txt; pip install ultralytics
git clone https://github.com/city96/ComfyUI-GGUF; pip install -r ComfyUI-GGUF/requirements.txt
git clone https://github.com/Smirnov75/ComfyUI-mxToolkit
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts
git clone https://github.com/kijai/ComfyUI-KJNodes; pip install -r ComfyUI-KJNodes/requirements.txt
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper; pip install -r ComfyUI-WanVideoWrapper/requirements.txt
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite; pip install -r ComfyUI-VideoHelperSuite/requirements.txt
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation
pip install cupy-cuda12x
cat ComfyUI-Frame-Interpolation/requirements-with-cupy.txt | grep -v 'cupy' | pip install -r /dev/stdin
git clone https://github.com/yolain/ComfyUI-Easy-Use; pip install -r ComfyUI-Easy-Use/requirements.txt
git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll; pip install -r ComfyUI_PuLID_Flux_ll/requirements.txt
git clone https://github.com/facok/ComfyUI-HunyuanVideoMultiLora
git clone https://github.com/WASasquatch/was-node-suite-comfyui; pip install -r was-node-suite-comfyui/requirements.txt
git clone https://github.com/kijai/ComfyUI-Florence2; pip install -r ComfyUI-Florence2/requirements.txt
git clone https://github.com/yuvraj108c/ComfyUI-Upscaler-Tensorrt; pip install -r ComfyUI-Upscaler-Tensorrt/requirements.txt
git clone https://github.com/pollockjj/ComfyUI-MultiGPU
git clone https://github.com/spacepxl/ComfyUI-Image-Filters.git
git clone https://github.com/jamesWalker55/comfyui-various.git
git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative
git clone https://github.com/alexopus/ComfyUI-Image-Saver; pip install -r ComfyUI-Image-Saver/requirements.txt
git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale
git clone https://github.com/Fannovel16/comfyui_controlnet_aux; pip install -r comfyui_controlnet_aux/requirements.txt
git clone https://github.com/XLabs-AI/x-flux-comfyui; pip install -r x-flux-comfyui/requirements.txt
git clone https://github.com/1038lab/ComfyUI-RMBG; pip install -r ComfyUI-RMBG/requirements.txt
git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon; pip install -r ComfyUI-Detail-Daemon/requirements.txt
git clone https://github.com/welltop-cn/ComfyUI-TeaCache; pip install -r ComfyUI-TeaCache/requirements.txt

# --- 4. Скачивание ZIP-архивов и установка ускорителей ---
download_with_retries "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/rgthree-comfy.zip" "rgthree-comfy.zip"
unzip rgthree-comfy.zip && rm rgthree-comfy.zip
pip install facexlib git+https://github.com/rodjjo/filterpy.git onnxruntime-gpu
cd ..
pip install -U xformers --index-url https://download.pytorch.org/whl/cu128
pip install triton
pip install --upgrade torchaudio torchvision
git clone https://github.com/NVIDIA/apex; pip install -v --disable-pip-version-check --no-cache-dir --no-build-isolation ./apex; rm -rf apex
git clone https://github.com/thu-ml/SageAttention.git; pip install ./SageAttention; rm -rf SageAttention

# --- 5. Загрузка моделей ---
echo "Загрузка моделей и настроек..."
mkdir -p user/default/workflows
MODELS_PATH="/workspace/ComfyUI/models"

download_with_retries "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/main/others/comfy.settings.json" "user/default/comfy.settings.json"
sleep 10 
download_with_retries "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "${MODELS_PATH}/vae/wan_2.1_vae.safetensors"
sleep 10
download_with_retries "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "${MODELS_PATH}/clip_vision/clip_vision_h.safetensors"
sleep 10
download_with_retries "https://huggingface.co/city96/umt5-xxl-encoder-gguf/resolve/main/umt5-xxl-encoder-Q5_K_S.gguf" "${MODELS_PATH}/clip/umt5-xxl-encoder-Q5_K_S.gguf"
sleep 10
download_with_retries "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q5_K_S.gguf" "${MODELS_PATH}/unet/wan2.1-i2v-14b-480p-Q5_K_S.gguf"
sleep 10
download_with_retries "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q5_K_S.gguf" "${MODELS_PATH}/unet/wan2.1-i2v-14b-720p-Q5_K_S.gguf"

CIVITAI_URL="https://civitai.com/api/download/models/2013104?type=Model&format=SafeTensor"
LORA_PATH="${MODELS_PATH}/loras/livewallpaper_720p.safetensors"
download_with_retries "$CIVITAI_URL" "$LORA_PATH"

echo "Загрузка моделей завершена!"

# --- 6. Финальный запуск ---
echo "--- Установка полностью завершена. Запускаю ComfyUI с корректными параметрами... ---"

# Это единственно верная команда запуска, которая объединяет все нужные флаги:
# --listen:           ОБЯЗАТЕЛЬНО. Делает веб-интерфейс доступным для системы туннелей.
# --lowvram:          Рекомендуется для оптимизации использования видеопамяти.
# --use-sage-attention: Включает оптимизацию внимания, которую мы установили.
# --port 8189:        Явно указывает порт, который мы будем пробрасывать.
python /workspace/ComfyUI/main.py --listen --lowvram --use-sage-attention --port 8189