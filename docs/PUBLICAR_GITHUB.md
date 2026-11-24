# Publicar y conservar el diseño

La portada pública es README.md con marca mocotoyo. La versión interna DATEC se entrega por separado. El diseño usa un banner SVG, tablas Markdown y Mermaid. No depende de CSS personalizado dentro del README.

## Archivos necesarios

Subir el contenido de aws-eks-mesh-lab/, incluidos docs/assets/, docs/GUIA_COMPLETA.md y .github/. No subir la carpeta version-interna/ al repositorio público. No subir .state/, .env.lab ni credenciales.

## Publicación

Crear un repositorio vacío llamado aws-eks-mesh-lab en la cuenta mocotoyo. Desde la raíz del proyecto:

```bash
git init -b main
git add .
git status
git commit -m "Publicar laboratorio EKS con portada y guia"
git remote add origin https://github.com/mocotoyo/aws-eks-mesh-lab.git
git push -u origin main
```

Si Git u origin ya están configurados, revisar la configuración antes de repetir comandos. No forzar un push sobre trabajo previo. El README debe quedar en la raíz del repositorio.

## About

Descripción sugerida: Laboratorio de CI/CD y Service Mesh en Amazon EKS con Istio, Kiali y control de costos.

Topics sugeridos: aws, eks, kubernetes, istio, service-mesh, github-actions, devsecops, kiali.

## Vista previa

El archivo preview.html es una representación local de la portada con formato similar al lector de Markdown de GitHub. Permite revisar la jerarquía y las secciones. Los controles de GitHub no son una sesión conectada ni ejecutan acciones por sí mismos. GitHub aplica sus propias tipografías, anchos y tema.

Para ver los diagramas Mermaid exactamente, usar la vista renderizada del README en GitHub. La vista previa local incluye una versión estática del mismo flujo.

## Después de ejecutar

Añadir capturas reales a docs/images/ y enlazarlas en el README. Revisar cuenta, endpoints y datos sensibles antes de publicar. No presentar resultados esperados como resultados ejecutados.
