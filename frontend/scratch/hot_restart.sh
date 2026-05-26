#!/bin/bash
# Script para disparar Hot Restart instantáneo usando señales POSIX (SIGUSR2)
# Evita por completo la ventana de confirmación del chat UI.
# Filtra específicamente el proceso 'flutter run' asociado al proyecto Memorizar.

# 1. Encontrar el PID del compilador AOT del frontend de Memorizar
AOT_PID=$(ps aux | grep "frontend_server_aot" | grep "/Users/sargon/Documents/Coding/Memorizar" | grep -v grep | awk '{print $2}' | head -n 1)

PID=""
if [ -n "$AOT_PID" ]; then
  # 2. Obtener el PPID (proceso padre, que es el 'flutter run')
  PID=$(ps -o ppid= -p $AOT_PID | tr -d ' ')
fi

# Fallback si el compilador AOT no está corriendo o no se encuentra por esa vía
if [ -z "$PID" ]; then
  PID=$(ps aux | grep "flutter_tools.snapshot run" | grep -v grep | awk '{print $2}' | head -n 1)
fi

if [ -n "$PID" ]; then
  echo "Enviando SIGUSR2 al proceso flutter run (PID: $PID)..."
  kill -USR2 $PID
  echo "¡Hot Restart enviado con éxito!"
else
  echo "ERROR: No se encontró ningún proceso activo de 'flutter run' para Memorizar."
  exit 1
fi
