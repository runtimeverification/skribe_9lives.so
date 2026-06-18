use stylus_sdk::{alloy_primitives::*};

use crate::error::*;

#[cfg(feature = "trading-backend-dppm")]
use crate::share_call;

use alloc::{borrow::ToOwned, string::String, vec::Vec};

// This exports user_entrypoint, which we need to have the entrypoint code.
pub use crate::storage_trading::*;

use bobcat_features::bobcat_feature;

// Should this contract use internal tokens instead of erc20?
bobcat_feature!(internal_tokens);

#[cfg_attr(feature = "contract-trading-skribe", stylus_sdk::prelude::public)]
impl StorageTrading {

    #[allow(clippy::too_many_arguments)]
    pub fn ctor_skribe(
        &mut self,
        outcomes: Vec<FixedBytes<8>>,
        oracle: Address,
        time_start: u64,
        time_ending: u64,
        fee_recipient: Address,
        should_buffer_time: bool,
        fee_creator: u64,
        fee_lp: u64,
        fee_minter: u64,
        fee_referrer: u64,
        seed_liq: U256,
    ) -> R<()> {
        self.internal_ctor(outcomes, oracle, time_start, time_ending, fee_recipient, should_buffer_time, fee_creator, fee_lp, fee_minter, fee_referrer, seed_liq)
    }

    pub fn decide_skribe(&mut self, outcome: FixedBytes<8>) -> R<U256> {
        self.internal_decide(outcome)
    }

    pub fn mint_skribe(
        &mut self,
        outcome: FixedBytes<8>,
        value: U256,
        recipient: Address,
    ) -> R<U256> {
        self.mint_8_A_059_B_6_E(outcome, value, Address::ZERO, recipient)
    }

    pub fn payoff_skribe(
        &mut self,
        outcome_id: FixedBytes<8>,
        amt: U256,
        recipient: Address,
    ) -> R<U256> {
        self.payoff_C_B_6_F_2565(outcome_id, amt, recipient)
    }
}
