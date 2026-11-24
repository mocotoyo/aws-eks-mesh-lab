#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
aws_state
vpc=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query cluster.resourcesVpcConfig.vpcId --output text)
printf '%s\n' "$vpc" > .state/vpc-id
mapfile -t asgs < <(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name lab --query 'nodegroup.resources.autoScalingGroups[].name' --output text | tr '\t' '\n')
mapfile -t instances < <(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${asgs[@]}" --query 'AutoScalingGroups[].Instances[].InstanceId' --output text | tr '\t' '\n')
((${#instances[@]}==1)) || fail 'El perfil económico espera exactamente un nodo'
# Standard evita cargos por créditos excedentes de T3 Unlimited. Puede reducir CPU sostenida.
aws ec2 modify-instance-credit-specification --instance-credit-specifications "InstanceId=${instances[0]},CpuCredits=standard"
mapfile -t volumes < <(aws ec2 describe-instances --instance-ids "${instances[@]}" --query 'Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId' --output text | tr '\t' '\n')
aws ec2 create-tags --resources "$vpc" "${instances[@]}" "${volumes[@]}" --tags Key=proyecto,Value=mesh-lab Key=lab-id,Value="$LAB_ID" Key=owner,Value="$GH_OWNER" Key=expires-at,Value="$EXPIRES_AT"
# Comprobación real, filtrada al VPC del laboratorio. No exige que toda la cuenta esté vacía.
count=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc" --query "length(NatGateways[?State!='deleted'])" --output text)
[[ "$count" == 0 ]] || fail 'Se detectó NAT Gateway en el VPC de prueba. Revisar y limpiar.'
