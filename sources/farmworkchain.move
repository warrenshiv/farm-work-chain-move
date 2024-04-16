module farm_work_chain::farm_work_chain {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock, timestamp_ms};
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext, sender};
    use sui::table::{Self, Table};

    use std::option::{Option, none, some, is_some, contains, borrow};
    use std::string::{Self, String};
    use std::vector::{Self};
    
    // Errors
    const ERROR_INVALID_SKILL: u64 = 0;
    
    // Struct definitions

    // FarmWork struct
    struct FarmWork has key, store {
        id: UID,
        inner: ID,
        workers: Table<address, Worker>,
        description: String,
        required_skills: vector<String>,
        category: String,
        price: u64,
        pay: Balance<SUI>,
        dispute: bool,
        rating: Option<u64>,
        status: String,
        worker: Option<address>,
        workSubmitted: bool,
        created_at: u64,
        deadline: u64,
    }

    struct FarmWorkCap has key {
        id: UID,
        farm_id: ID
    }

    struct Worker has key, store {
        id: UID,
        farm_id: ID,
        owner: address,
        description: String,
        skills: vector<String>
    }
    
    // Accessors
    // public entry fun get_work_description(work: &FarmWork): vector<u8> {
    //     work.description
    // }

    // public entry fun get_work_price(work: &FarmWork): u64 {
    //     work.price
    // }

    // public entry fun get_work_status(work: &FarmWork): vector<u8> {
    //     work.status
    // }

    // public entry fun get_work_deadline(work: &FarmWork): u64 {
    //     work.deadline
    // }

    // Public - Entry functions

    // Create a new work
    public entry fun new_farm(
        c: &Clock, 
        description_: String,
        category_: String,
        price_: u64, 
        duration_: u64, 
        open_: String, 
        ctx: &mut TxContext
        ) {
        let id_ = object::new(ctx);
        let inner_ = object::uid_to_inner(&id_);
        let deadline_ = timestamp_ms(c) + duration_;

        transfer::share_object(FarmWork {
            id: id_,
            inner: inner_,
            workers: table::new(ctx),
            description: description_,
            required_skills: vector::empty(),
            category: category_,
            price: price_,
            pay: balance::zero(),
            dispute: false,
            rating: none(),
            status: open_,
            worker: none(),
            workSubmitted: false,
            created_at: timestamp_ms(c),
            deadline: deadline_
        });

        transfer::transfer(FarmWorkCap{id: object::new(ctx), farm_id: inner_}, sender(ctx));
    }
    // Users should create new worker for bid 
    public fun new_worker(farm: ID, description_: String, ctx: &mut TxContext) : Worker {
        let worker = Worker {
            id: object::new(ctx),
            farm_id: farm,
            owner: sender(ctx),
            description: description_,
            skills: vector::empty()
        };
        worker
    }
    // users can set new skills
    public fun add_skill(self: &mut Worker, skill: String) {
        assert!(!vector::contains(&self.skills, &skill), ERROR_INVALID_SKILL);
        vector::push_back(&mut self.skills, skill);
    }
    // users can bid to works
    public fun bid_work(farm: &mut FarmWork, worker: Worker, ctx: &mut TxContext) {
        table::add(&mut farm.workers, sender(ctx), worker);
    }
    
    
}
