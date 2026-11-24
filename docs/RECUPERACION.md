# Recuperación y limpieza de una ejecución parcial

## Si setup falla

Conservar `.state/`, el perfil AWS y `.env.lab`. No ejecutar otra creación con el mismo nombre hasta revisar el intento anterior.

```bash
bash cleanup.sh --plan
bash cleanup.sh --aws --apply
```

Si el script falla por sesión expirada, renovar el perfil (`aws sso login --profile ...`) y repetir. Los errores no se convierten en éxito. Si el clúster sigue en creación, una eliminación puede necesitar esperar a que termine esa operación. El timer local reintenta errores cada cinco minutos mientras el servicio y las credenciales funcionen.

## Botón DELETE todavía no configurado

El rol DELETE y sus targets se generan al final del setup AWS. Si la configuración falló antes de ese punto, el botón no podrá asumir ese rol. Usar la limpieza local como administradora. Esta diferencia importa porque el presupuesto ya puede existir mientras EKS todavía no existe.

## Eliminación manual desde AWS Console

1. Confirmar cuenta, región y nombre del laboratorio.
2. En CloudFormation localizar únicamente `eksctl-mocotoyo-mesh-demo-nodegroup-lab` y `eksctl-mocotoyo-mesh-demo-cluster` (adaptar al LAB_ID real).
3. Comprobar sus etiquetas `lab-id` y los recursos antes de borrar.
4. Si añadiste LoadBalancer Services, PVC o integraciones, retirarlos primero con Kubernetes. Este kit no los crea.
5. Eliminar el stack del nodegroup y esperar `DELETE_COMPLETE`.
6. Eliminar el stack del clúster y esperar `DELETE_COMPLETE`.
7. Si hay `DELETE_FAILED`, leer el evento concreto. No eliminar VPC/subredes de otros proyectos.
8. En EKS confirmar que el clúster ya no aparece.
9. En ECR eliminar solamente el repositorio del laboratorio y sus imágenes.
10. Revisar EC2, EBS, IPv4, ELB y logs del VPC/laboratorio. Eliminar únicamente residuos cuyo origen esté comprobado.

Un fallo de permisos del rol DELETE no autoriza a sustituirlo por AdministratorAccess en GitHub. Recuperar con la identidad administradora de la cuenta y ajustar los permisos específicos si se va a repetir la prueba.

## Si perdiste el estado local

El botón GitHub utiliza `LAB_DELETE_TARGETS` almacenado en el entorno lab y puede seguir funcionando. Revisar cuenta y región en consola. No reconstruir targets por coincidencias amplias ni borrar por una etiqueta genérica que puedan compartir otros proyectos.

## Qué se conserva

El presupuesto y proveedor OIDC se conservan. El botón también conserva el rol DELETE, que no tiene cargo por existir y permite reintentos. El cleanup local elimina ese rol después de completar la infraestructura.

Los recursos IAM conservados deben revisarse si abandonas definitivamente el repositorio. Eliminar el proveedor OIDC compartido puede afectar otras integraciones.

## Facturación tardía

Volver a revisar Billing cuando se actualicen los cargos. EKS no se deja de cobrar por cerrar una terminal, apagar WSL, reducir nodos a cero o detener pods. Se necesita eliminar el control plane y los otros recursos facturables.
