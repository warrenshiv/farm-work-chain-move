module freelance_marketplace::freelance_marketplace {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Option, none, some, is_some, contains, borrow};
    
    // Errors
    const EInvalidBid: u64 = 1;
    const EInvalidWork: u64 = 2;
    const EDispute: u64 = 3;
    const EAlreadyResolved: u64 = 4;
    const ENotworker: u64 = 5;
    const EInvalidWithdrawal: u64 = 7;
    
    // Struct definitions
    struct FarmWork has key, store {
        id: UID,
        farmer: address,
        description: vector<u8>,
        price: u64,
        deadline: u64,
        escrow: Balance<SUI>,
        dispute: bool,
        worker: Option<address>,
        workSubmitted: bool,
    }

    // Module initializer
    
    // Accessors
    public entry fun get_work_description(work: &FarmWork): vector<u8> {
        work.description
    }

    public entry fun get_work_price(work: &FarmWork): u64 {
        work.price
    }

    // Public - Entry functions
    public entry fun create_work(description: vector<u8>, price: u64, ctx: &mut TxContext) {
        
        let work_id = object::new(ctx);
        transfer::share_object(FarmWork {
            id: work_id,
            farmer: tx_context::sender(ctx),
            worker: none(), // Set to an initial value, can be updated later
            description: description,
            deadline: 0, // Set to an initial value, can be updated later
            price: price,
            escrow: balance::zero(),
            workSubmitted: false,
            dispute: false,
        });
    }

    public entry fun hire_worker(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(!is_some(&work.worker), EInvalidBid);
        work.worker = some(tx_context::sender(ctx));
    }

    public entry fun submit_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(contains(&work.worker, &tx_context::sender(ctx)), EInvalidWork);
        work.workSubmitted = true;
    }

    public entry fun dispute_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), EDispute);
        work.dispute = true;
    }

    public entry fun resolve_dispute(work: &mut FarmWork, resolved: bool, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), EDispute);
        assert!(work.dispute, EAlreadyResolved);
        assert!(is_some(&work.worker), EInvalidBid);
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        if (resolved) {
            let worker = *borrow(&work.worker);
            // Transfer funds to the worker
            transfer::public_transfer(escrow_coin, worker);
        } else {
            // Refund funds to the farmer
            transfer::public_transfer(escrow_coin, work.farmer);
        };

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
    }

    public entry fun release_payment(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotworker);
        assert!(work.workSubmitted && !work.dispute, EInvalidWork);
        assert!(is_some(&work.worker), EInvalidBid);
        let worker = *borrow(&work.worker);
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        // Transfer funds to the worker
        transfer::public_transfer(escrow_coin, worker);

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
    }

    // Additional functions
    public entry fun cancel_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx) || contains(&work.worker, &tx_context::sender(ctx)), ENotworker);
        
        // Refund funds to the farmer if not yet paid
        if (is_some(&work.worker) && !work.workSubmitted && !work.dispute) {
            let escrow_amount = balance::value(&work.escrow);
            let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
            transfer::public_transfer(escrow_coin, work.farmer);
        };

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
    }

    public entry fun update_work_description(work: &mut FarmWork, new_description: vector<u8>, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotworker);
        work.description = new_description;
    }

    public entry fun update_work_price(work: &mut FarmWork, new_price: u64, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotworker);
        work.price = new_price;
    }

    // New functions
    public entry fun add_funds_to_work(work: &mut FarmWork, amount: Coin<SUI>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
        let added_balance = coin::into_balance(amount);
        balance::join(&mut work.escrow, added_balance);
    }

    public entry fun request_refund(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
        assert!(work.workSubmitted == false, EInvalidWithdrawal);
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        // Refund funds to the farmer
        transfer::public_transfer(escrow_coin, work.farmer);

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
    }
    
    // public entry fun update_work_deadline(work: &mut FarmWork, new_deadline: u64, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
    //     // Additional logic to update the work's deadline
    // }

    public entry fun mark_work_complete(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(contains(&work.worker, &tx_context::sender(ctx)), ENotworker);
        work.workSubmitted = true;
        // Additional logic to mark the work as complete
    }
    
    // public entry fun extend_dispute_period(work: &mut FarmWork, extension_days: u64, ctx: &mut TxContext) {
    //     assert!(tx_context::sender(ctx) == work.farmer, ENotworker);
    //     assert!(work.dispute, EInvalidUpdate);
    //     // Additional logic to extend the dispute period
    // }
}
