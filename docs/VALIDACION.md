# Estado de validación

Preparación: 24 de noviembre de 2026.

## Comprobaciones disponibles sin crear AWS

- Sintaxis de scripts Bash y Python.
- Parseo de YAML de manifiestos y workflows.
- Referencias de acciones externas fijadas a 40 caracteres y consultadas en sus repositorios oficiales vía API GitHub.
- Plan de costos, rechazo por umbral y rechazo de ventanas fuera del rango permitido.
- Aplicación HTTP local con respuestas GET y POST.
- Aislamiento de targets y rechazo de cuenta/confirmación incorrecta en el código de eliminación mediante dobles de AWS CLI.
- Referencias locales de documentación y archivos del paquete.

## Pendiente con la cuenta de laboratorio

Creación EKS, disponibilidad regional/versiones, presupuesto y notificaciones reales, integración OIDC, ejecución Actions, imagen aprobada por Trivy, descarga de addons, mTLS, Kiali, autorización, temporizador local y eliminación real con el rol de CloudFormation.

No se generaron salidas AWS ficticias. El rol de eliminación usa permisos limitados a un inventario y debe comprobarse en la cuenta real. Cambios de AWS, eksctl o CloudFormation pueden requerir permisos adicionales específicos. Un DELETE fallido necesita seguimiento hasta que desaparezcan los recursos facturables.

El resultado del ensayo local completo también requiere Docker, kind y Helm, que no estaban disponibles en el entorno de preparación. Las validaciones de código no equivalen a esa ejecución.

## Ejecutar las comprobaciones

```bash
python3 -m unittest discover -s tests -v
bash setup.sh --plan
```

Resultado en preparación: **9 pruebas aprobadas**. Aplicación HTTP local: GET 200 y POST 201.
