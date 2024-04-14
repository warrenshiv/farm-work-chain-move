module farm_work_chain::farm {

    // Imports
    use sui::transfer;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Option, none, some};

    // Errors
    const EInvalidBid: u64 = 1;
    const EInvalidWork: u64 = 2;
    const EDispute: u64 = 3;
    const EAlreadyResolved: u64 = 4;
    const ENotFarmer: u64 = 5;
    const EInvalidWithdrawal: u64 = 6;
    const EDeadlinePassed: u64 = 7;

    // Struct definitions
    struct FarmWork has key, store {
        id: UID,
        farmer: address,
        description: vector<u8>,
        price: u64,
        deadline: u64,
        escrow: Balance<SUI>,
        workSubmitted: bool,
        dispute: bool,
        rating: Option<u8>,
        worker: Option<address>,
        status: WorkStatus,
        documents: vector<vector<u8>>,
    }

    public enum WorkStatus {
        Open,
        InProgress,
        Completed,
        Canceled,
    }

    // Accessors
    public entry fun get_work_description(work: &FarmWork): vector<u8> {
        work.description
    }

    public entry fun get_work_price(work: &FarmWork): u64 {
        work.price
    }

    public entry fun get_work_status(work: &FarmWork): WorkStatus {
        work.status
    }

    public entry fun get_work_deadline(work: &FarmWork): u64 {
        work.deadline
    }

    public entry fun get_work_rating(work: &FarmWork): Option<u8> {
        work.rating
    }

    // Public - Entry functions
    public entry fun create_work(description: vector<u8>, price: u64, deadline: u64, ctx: &mut TxContext) {
        
        let work_id = object::new(ctx);
        transfer::share_object(FarmWork {
            id: work_id,
            farmer: tx_context::sender(ctx),
            description: description,
            price: price,
            deadline: deadline,
            escrow: balance::zero(),
            workSubmitted: false,
            dispute: false,
            rating: none(),
            worker: none(),
            status: WorkStatus::Open,
            documents: vector::empty(),
        });
    }

    public entry fun hire_worker(work: &mut FarmWork, worker: address, ctx: &mut TxContext) {
        assert!(work.worker == none(), EInvalidBid);
        work.worker = some(worker);
    }

    public entry fun submit_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.worker == some(tx_context::sender(ctx)), EInvalidWork);
        assert!(ctx.get_block_timestamp() <= work.deadline, EDeadlinePassed);
        work.workSubmitted = true;
        work.status = WorkStatus::InProgress;
    }

    public entry fun dispute_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), EDispute);
        work.dispute = true;
    }

    public entry fun resolve_dispute(work: &mut FarmWork, resolved: bool, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), EDispute);
        assert!(work.dispute, EAlreadyResolved);
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        if (resolved) {
            let worker = work.worker.unwrap();
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
        work.status = WorkStatus::Canceled;
    }

    public entry fun rate_worker(work: &mut FarmWork, rating: u8, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotFarmer);
        assert!(work.status == WorkStatus::Completed, EInvalidWork);
        work.rating = some(rating);
    }

    public entry fun release_payment(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotFarmer);
        assert!(work.workSubmitted && !work.dispute && work.status == WorkStatus::InProgress, EInvalidWork);
        let worker = work.worker.unwrap();
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        // Transfer funds to the worker
        transfer::public_transfer(escrow_coin, worker);

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
        work.status = WorkStatus::Completed;
    }

    // Additional functions
    public entry fun cancel_work(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx) || work.worker == some(tx_context::sender(ctx)), ENotFarmer);
        
        // Refund funds to the farmer if not yet paid
        if (work.worker != none() && !work.workSubmitted && !work.dispute) {
            let escrow_amount = balance::value(&work.escrow);
            let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
            transfer::public_transfer(escrow_coin, work.farmer);
        };

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
        work.status = WorkStatus::Canceled;
    }

    public entry fun update_work_description(work: &mut FarmWork, new_description: vector<u8>, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotFarmer);
        work.description = new_description;
    }

    public entry fun update_work_price(work: &mut FarmWork, new_price: u64, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx), ENotFarmer);
        work.price = new_price;
    }

    public entry fun add_funds_to_work(work: &mut FarmWork, amount: Coin<SUI>, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == work.farmer, ENotFarmer);
        let added_balance = coin::into_balance(amount);
        balance::join(&mut work.escrow, added_balance);
    }

    public entry fun request_refund(work: &mut FarmWork, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == work.farmer, ENotFarmer);
        assert!(work.workSubmitted == false, EInvalidWithdrawal);
        let escrow_amount = balance::value(&work.escrow);
        let escrow_coin = coin::take(&mut work.escrow, escrow_amount, ctx);
        // Refund funds to the farmer
        transfer::public_transfer(escrow_coin, work.farmer);

        // Reset work state
        work.worker = none();
        work.workSubmitted = false;
        work.dispute = false;
        work.status = WorkStatus::Canceled;
    }

    public entry fun upload_document(work: &mut FarmWork, document: vector<u8>, ctx: &mut TxContext) {
        assert!(work.farmer == tx_context::sender(ctx) || work.worker == some(tx_context::sender(ctx)), ENotFarmer);
        work.documents.push(document);
    }
}
