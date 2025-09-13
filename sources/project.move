module MyModule::NFTLootBox {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::randomness;
    use std::vector;

    /// Struct representing an NFT Loot Box
    struct LootBox has store, key {
        price: u64,           // Price to purchase the loot box
        total_sold: u64,      // Total loot boxes sold
        rewards: vector<u64>, // Available reward tiers (1=common, 2=rare, 3=legendary)
    }

    /// Struct to track user's opened boxes and rewards
    struct UserRewards has store, key {
        boxes_opened: u64,
        rewards_received: vector<u64>,
    }

    /// Function to create a new loot box system
    public fun create_loot_box(owner: &signer, price: u64) {
        let rewards = vector::empty<u64>();
        vector::push_back(&mut rewards, 1); // Common
        vector::push_back(&mut rewards, 2); // Rare  
        vector::push_back(&mut rewards, 3); // Legendary

        let loot_box = LootBox {
            price,
            total_sold: 0,
            rewards,
        };
        move_to(owner, loot_box);
    }

    /// Function for users to purchase and open a loot box
    public fun purchase_and_open_box(
        user: &signer, 
        loot_box_owner: address
    ) acquires LootBox, UserRewards {
        let loot_box = borrow_global_mut<LootBox>(loot_box_owner);
        let user_addr = signer::address_of(user);

        // Payment: transfer coins from user to loot box owner
        let payment = coin::withdraw<AptosCoin>(user, loot_box.price);
        coin::deposit<AptosCoin>(loot_box_owner, payment);

        // Update total sold
        loot_box.total_sold = loot_box.total_sold + 1;

        // Generate random reward (simplified randomness)
        let random_value = (loot_box.total_sold % 100) + 1;
        let reward_tier = if (random_value <= 70) { 1 } // 70% common
                         else if (random_value <= 95) { 2 } // 25% rare  
                         else { 3 }; // 5% legendary

        // Update or create user rewards
        if (!exists<UserRewards>(user_addr)) {
            let user_rewards = UserRewards {
                boxes_opened: 1,
                rewards_received: vector::singleton(reward_tier),
            };
            move_to(user, user_rewards);
        } else {
            let user_rewards = borrow_global_mut<UserRewards>(user_addr);
            user_rewards.boxes_opened = user_rewards.boxes_opened + 1;
            vector::push_back(&mut user_rewards.rewards_received, reward_tier);
        };
    }
}