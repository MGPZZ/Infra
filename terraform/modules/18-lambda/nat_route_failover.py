import json
import logging
import os
import boto3

"""
Cloudwatch가 볼 수 있게 로그를 남기기 위한 LOGGER객체 생성
Ec2의 기능을 사용하기 위한 EC2객체 생성
"""
LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
EC2 = boto3.client("ec2")

# event 파라미터에는 alarmName: "side-project-nat-x-status-check" 키 값 형태로 전달함 cloudwatch에서 자동으로 넣어줌
"""
Cloudwatch에서 아래 블럭과 같은 형식으로 넘겨줌
{
  "alarmData": {
    "alarmName": "side-project-nat-a-status-check",
    "state": {
      "value": "ALARM"
    }
  }
}
"""
# Cloudwatch에서 넘긴 값 중 알람 이름을 꺼내는 함수
def _alarm_name(event):
    return event.get("alarmData", {}).get("alarmName") or event.get("AlarmName")

# Cloudwatch에서 넘긴 값 중 알람 상태를 꺼내는 함수
def _alarm_state(event):
    return event.get("alarmData", {}).get("state", {}).get("value") or event.get("NewStateValue")

# lambda 실행할 때 호출하는 시작 함수
def lambda_handler(event, _context):
    alarm_name = _alarm_name(event)
    alarm_state = _alarm_state(event)
    routes = json.loads(os.environ["NAT_ROUTES"]) #장애난 ec2가 무엇인지 뽑아오는 문장 
    route = routes.get(alarm_name) # routes 블럭에 있던 값들을 뽑아오는 문장 

    if route is None:
        raise ValueError(f"No NAT route configuration exists for alarm: {alarm_name}")

    if alarm_state == "ALARM":          # 장애발생 했을 때 failover를 위해 살아있는 nat instance를 보게하기
        target_eni = route["standby_network_interface_id"]
    elif alarm_state == "OK":           # 장애 해결 됐을 때 원래 nat instance를 보게하기
        target_eni = route["primary_network_interface_id"]
    else:                               # 장애발생도 장애해결도 아니라면 무시하기
        LOGGER.info("Ignoring %s state for %s", alarm_state, alarm_name)
        return {"status": "ignored", "alarm_name": alarm_name, "alarm_state": alarm_state}

    # failover 및 복구했을 때 라우팅을 원래대로 만들어주는 블럭
    EC2.replace_route(
        RouteTableId=route["route_table_id"],
        DestinationCidrBlock="0.0.0.0/0",
        NetworkInterfaceId=target_eni,
    )
    # 죽어있는 nat instance 재시작
    if alarm_state == "ALARM":
        EC2.reboot_instances(InstanceIds=[route["primary_instance_id"]])
        LOGGER.info("Rebooted failed NAT instance %s", route["primary_instance_id"])
        
    # cloudwatch용 기록 남기기 블럭
    LOGGER.info(
        "Updated route table %s for %s to NAT ENI %s",
        route["route_table_id"],
        alarm_name,
        target_eni,
    )
    return {"status": "updated", "alarm_name": alarm_name, "target_eni": target_eni}
