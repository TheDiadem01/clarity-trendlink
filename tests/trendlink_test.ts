import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test topic creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const deadline = chain.blockHeight + 100;
    
    let block = chain.mineBlock([
      Tx.contractCall('trendlink', 'create-topic', [
        types.ascii("Will AI surpass human intelligence by 2030?"),
        types.uint(deadline),
        types.list([types.ascii("Yes"), types.ascii("No")])
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Test prediction making and reward claiming",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const deadline = chain.blockHeight + 100;
    
    // Create topic
    let block = chain.mineBlock([
      Tx.contractCall('trendlink', 'create-topic', [
        types.ascii("Will AI surpass human intelligence by 2030?"),
        types.uint(deadline),
        types.list([types.ascii("Yes"), types.ascii("No")])
      ], deployer.address)
    ]);
    
    // Make prediction
    block = chain.mineBlock([
      Tx.contractCall('trendlink', 'make-prediction', [
        types.uint(1),
        types.uint(0),
        types.uint(100)
      ], user1.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Advance blockchain and resolve topic
    chain.mineEmptyBlockUntil(deadline + 1);
    
    block = chain.mineBlock([
      Tx.contractCall('trendlink', 'resolve-topic', [
        types.uint(1),
        types.uint(0)
      ], deployer.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Claim rewards
    block = chain.mineBlock([
      Tx.contractCall('trendlink', 'claim-rewards', [
        types.uint(1)
      ], user1.address)
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
