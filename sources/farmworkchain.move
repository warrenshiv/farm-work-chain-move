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
    const ERROR_FARM_CLOSED: u64 = 1;
    const ERROR_INVALID_CAP :u64 = 2;
    const ERROR_INSUFFCIENT_FUNDS :u64 = 3;
    const ERROR_WORK_NOT_SUBMIT :u64 = 4;
    const ERROR_WRONG_ADDRESS :u64 = 5;
    const ERROR_TIME_IS_UP :u64 = 5;

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
        status: bool,
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
    public fun get_work_description(work: &FarmWork): String {
        work.description
    }

    public fun get_work_price(work: &FarmWork): u64 {
        work.price
    }

    public fun get_work_status(work: &FarmWork): bool {
        work.status
    }

    public fun get_work_deadline(work: &FarmWork): u64 {
        work.deadline
    }

    // Public - Entry functions

    // Create a new work
    public entry fun new_farm(
        c: &Clock, 
        description_: String,
        category_: String,
        price_: u64, 
        duration_: u64, 
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
            status: false,
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
        assert!(!farm.status, ERROR_FARM_CLOSED);
        table::add(&mut farm.workers, sender(ctx), worker);
    }
    // farmwork owner should choose worker and send to worker object to choosen.
    public fun choose(cap: &FarmWorkCap, farm: &mut FarmWork, coin: Coin<SUI>, choosen: address) : Worker {
        assert!(cap.farm_id == object::id(farm), ERROR_INVALID_CAP);
        assert!(coin::value(&coin) >= farm.price, ERROR_INSUFFCIENT_FUNDS);

        let worker = table::remove(&mut farm.workers, choosen);
        let balance_ = coin::into_balance(coin);
        // submit the worker balance 
        balance::join(&mut farm.pay, balance_);
        // farm closed. 
        farm.status = true;
        // set the worker address 
        farm.worker = some(choosen);
        worker
    }

    public fun submit_work(self: &mut FarmWork, c:&Clock, ctx: &mut TxContext) {
        assert!(timestamp_ms(c) < self.deadline, ERROR_TIME_IS_UP);
        assert!(*borrow(&self.worker) == sender(ctx), ERROR_WRONG_ADDRESS);
        self.workSubmitted = true;
    }

    public fun confirm_work(cap: &FarmWorkCap, self: &mut FarmWork, ctx: &mut TxContext) {
        assert!(cap.farm_id == object::id(self), ERROR_INVALID_CAP);
        assert!(self.workSubmitted, ERROR_WORK_NOT_SUBMIT);
        
        let balance_ = balance::withdraw_all(&mut self.pay);
        let coin_ = coin::from_balance(balance_, ctx);
        
        transfer::public_transfer(coin_, *borrow(&self.worker));
    }  
}
