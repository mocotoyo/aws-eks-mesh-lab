# Guion de demostración

**Proyecto:** mocotoyo AWS Lab.
Presentadora: Mónica Torrico. Audiencia: equipo técnico o cliente en sesión de laboratorio.

No crear EKS durante la exposición inicial si el objetivo es una demo breve. Ensayar localmente y preparar AWS dentro de la ventana de costo. Las pruebas AWS están pendientes hasta contar con evidencia real. Los números de diapositiva corresponden al deck de 14 láminas preparado en esta conversación.

| Diapositiva | Qué decir | Qué mostrar | Evidencia |
|---|---|---|---|
| 1. Portada | “Este laboratorio muestra la entrega y protección de una aplicación sobre EKS.” | Portada con la marca de la audiencia | Contexto y alcance |
| 2. Propósito | “Seguiremos un cambio desde GitHub hasta el workload.” | Recorrido de la arquitectura | Un cambio identificable |
| 3. Alcance | “Esta revisión incorpora Kiali y autorización básica.” | Tabla de componentes actuales y futuros | Evitar presentar JWT/Argo como implementados |
| 4. Arquitectura | “GitHub publica en ECR y despliega. El acceso de demo usa port-forward.” | Mermaid del README | Sin NLB ni NAT |
| 5. Pipeline | “Trivy bloquea según el criterio de vulnerabilidades.” | Actions y digest de ECR | Workflow real y digest |
| 6. OIDC | “GitHub usa credenciales temporales. EKS limita el namespace.” | Claim esperado, access entry y RBAC | Nunca imprimir JWT o tokens |
| 7. Canary | “Los pesos configuran el reparto. El conteo es una muestra.” | 90/10, 50/50 y 0/100, luego Kiali | Conteos de las tres etapas |
| 8. mTLS | “STRICT rechaza clientes sin mesh. La comparación temporal aísla el control.” | STRICT, PERMISSIVE y vuelta a STRICT | Rechazo, aceptación, rechazo |
| 8. Ampliación de autorización | “Ahora comprobamos identidad y método, además del cifrado.” | auth-test: GET 200, POST 403, otra SA 403 | Salida del script con aserciones |
| 9. Preparación | “Preparé las dependencias antes de consumir EKS.” | Plan, presupuesto y timer | Plan y versión estándar |
| 10. Demostración | “Un push genera una entrega verificable.” | Cambio de código, rollout y respuesta JSON | Aplicación actualizada |
| 11. Evidencias | “Estos son los resultados de la sesión, con fecha y contexto.” | Pods, proxy-status y conteos reales | Nunca usar una salida de ejemplo como resultado |
| 12. Costos | “La base ronda USD 0,19/h. Presupuesto no equivale a corte.” | Tabla de costos y botón DELETE | Tiempo de la sesión y comprobación de cierre |
| 13. Próxima fase | “JWT y GitOps son ejercicios posteriores.” | Roadmap, con Kiali y AuthorizationPolicy ya incorporados en esta revisión | Alcance actualizado |
| 14. Cierre | “Terminamos eliminando la infraestructura y revisando residuos.” | Workflow DELETE y auditoría | Control plane ausente |

## Orden sugerido de la sesión en vivo

1. Mostrar plan de costos, vencimiento y contexto del clúster.
2. Abrir Actions con una ejecución terminada y comprobar el digest.
3. Abrir el gateway y Kiali. Generar tráfico suave.
4. Promover el canary y volver a 90/10.
5. Demostrar mTLS antes de AuthorizationPolicy.
6. Ejecutar autorización por ServiceAccount y método.
7. Guardar evidencias y ejecutar DELETE.
8. Esperar eliminación efectiva y revisar la cuenta.

La eliminación puede tardar más que la exposición. Reservar una ventana posterior y mantener la revisión hasta el cierre.
