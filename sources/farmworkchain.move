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
    
    // // Bid for work
    // public entry fun hire_worker(work: &mut FarmWork, ctx: &mut TxContext) {
    //     assert!(!is_some(&work.worker), EInvalidBid);
    //     work.worker = some(tx_context::sender(ctx));
    // }
    
    // // Submit work
    // public entry fun submit_work(work: &mut FarmWork, clock: &Clock, ctx: &mut TxContext) {
    //     assert!(contains(&work.worker, &tx_context::sender(ctx)), EInvalidWork);
    //     assert!(clock::timestamp_ms(clock) < work.deadline, EDeadlinePassed);
    //     work.workSubmitted = true;
    // }

    // // Mark work as complete
    // public entry fun mark_work_complete(work: &mut FarmWork, ctx: &mut TxContext) {
    //     assert!(contains(&work.worker, &tx_context::sender(ctx)), ENotworker);
    //     work.workSubmitted = true;
    // }
    
    // // Raise a dispute
    // public entry fun dispute_work(work: &mut FarmWork, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), EDispute);
    //     work.dispute = true;
    // }
    
    // // Resolve dispute if any between farmer and worker
    // public entry fun resolve_dispute(work: &mut FarmWork, resolved: bool, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), EDispute);
    //     assert!(work.dispute, EAlreadyResolved);
    //     assert!(is_some(&work.worker), EInvalidBid);
    //     let escrow_amount = balance::value(&work.escrow);
    //     let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
    //     if (resolved) {
    //         let worker = *borrow(&work.worker);
    //         // Transfer funds to the worker
    //         transfer::public_transfer(escrow_coin, worker);
    //     } else {
    //         // Refund funds to the farmer
    //         transfer::public_transfer(escrow_coin, work.farmer);
    //     };
        
    //     // Reset work state
    //     work.worker = none();
    //     work.workSubmitted = false;
    //     work.dispute = false;
    // }
    
    // // Release payment to the worker after work is completed
    // public entry fun release_payment(work: &mut FarmWork, clock: &Clock, review: vector<u8>, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     assert!(work.workSubmitted && !work.dispute, EInvalidWork);
    //     assert!(clock::timestamp_ms(clock) > work.deadline, EDeadlinePassed);
    //     assert!(is_some(&work.worker), EInvalidBid);
    //     let worker = *borrow(&work.worker);
    //     let escrow_amount = balance::value(&work.escrow);
    //     assert!(escrow_amount > 0, EInsufficientEscrow); // Ensure there are enough funds in escrow
    //     let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
    //     // Transfer funds to the worker
    //     transfer::public_transfer(escrow_coin, worker);

    //     // Create a new work record
    //     let workRecord = WorkRecord {
    //         id: object::new(ctx),
    //         farmer: tx_context::sender(ctx),
    //         review: review,
    //     };

    //     // Change accessiblity of work record
    //     transfer::public_transfer(workRecord, tx_context::sender(ctx));

    //     // Reset work state
    //     work.worker = none();
    //     work.workSubmitted = false;
    //     work.dispute = false;
    // }

    // // Add more cash at escrow
    // public entry fun add_funds(work: &mut FarmWork, amount: Coin<SUI>, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
    //     let added_balance = coin::into_balance(amount);
    //     balance::join(&mut work.escrow, added_balance);
    // }
    
    // // Cancel work
    // public entry fun cancel_work(work: &mut FarmWork, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx) || contains(&work.worker, &tx_context::sender(ctx)), ENotworker);
        
    //     // Refund funds to the farmer if not yet paid
    //     if (is_some(&work.worker) && !work.workSubmitted && !work.dispute) {
    //         let escrow_amount = balance::value(&work.escrow);
    //         let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
    //         transfer::public_transfer(escrow_coin, work.farmer);
    //     };
        
    //     // Reset work state
    //     work.worker = none();
    //     work.workSubmitted = false;
    //     work.dispute = false;
    // }

    // // Rate the worker
    // public entry fun rate_worker(work: &mut FarmWork, rating: u64, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.rating = some(rating);
    // }
    
    // // Update work description
    // public entry fun update_work_description(work: &mut FarmWork, new_description: vector<u8>, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.description = new_description;
    // }
    
    // // Update work price
    // public entry fun update_work_price(work: &mut FarmWork, new_price: u64, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.price = new_price;
    // }

    // // Update work category
    // public entry fun update_work_category(work: &mut FarmWork, new_category: vector<u8>, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.category = new_category;
    // }

    // // Update required skills
    // public entry fun update_work_skills(work: &mut FarmWork, new_skills: vector<u8>, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.required_skills = new_skills;
    // }

    // // Update deadline
    // public entry fun update_work_deadline(work: &mut FarmWork, new_deadline: u64, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.deadline = new_deadline;
    // }
    
    // // Update work status
    // public entry fun update_work_status(work: &mut FarmWork, completed: vector<u8>, ctx: &mut TxContext) {
    //     assert!(work.farmer == tx_context::sender(ctx), ENotworker);
    //     work.status = completed;
    // }

    // // Add more cash to escrow
    // public entry fun add_funds_to_work(work: &mut FarmWork, amount: Coin<SUI>, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
    //     let added_balance = coin::into_balance(amount);
    //     balance::join(&mut work.escrow, added_balance);
    // }
    

    // // Withdraw funds from escrow
    // public entry fun request_refund(work: &mut FarmWork, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
    //     assert!(work.workSubmitted == false, EInvalidWithdrawal);
    //     let escrow_amount = balance::value(&work.escrow);
    //     let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
    //     // Refund funds to the farmer
    //     transfer::public_transfer(escrow_coin, work.farmer);

    //     // Reset work state
    //     work.worker = none();
    //     work.workSubmitted = false;
    //     work.dispute = false;
    // }
    
    // // Work matching by skills and category
    // public entry fun match_work(skills: vector<u8>, category: vector<u8>, ctx: &TxContext): vector<FarmWork> {
    //     let all_works = object::all::<FarmWork>();
    //     let mut matched_works = vector<FarmWork>::new();
    //     for work in all_works {
    //         if (work.required_skills == skills && work.category == category) {
    //             matched_works.push(work);
    //         }
    //     }
    //     matched_works
    // }
}
