// Cooja headless 실행 스크립트
// 시뮬레이션을 자동으로 실행하고 종료

// 시뮬레이션 시간 설정 (milliseconds)
var SIM_TIME = 10 * 60 * 1000; // 10분

// 로그 출력
TIMEOUT(SIM_TIME, log.log("Simulation finished\n"));

log.log("Starting headless simulation for " + (SIM_TIME/1000) + " seconds\n");
log.log("Nodes: " + sim.getMotesCount() + "\n");

// 시뮬레이션 시작은 Cooja가 자동으로 수행
