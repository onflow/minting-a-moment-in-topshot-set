import "TopShot"

transaction {
    
    let admin: auth(AdminEntitlement) &TopShot.Admin
    let borrowedSet: &TopShot.Set

    prepare(acct: auth(Storage, Capabilities) &Account) {
        // Borrow the admin resource
        self.admin = acct.capabilities.storage.borrow<&TopShot.Admin>(
            from: /storage/TopShotAdmin
        ) ?? panic("Can't borrow admin resource")

        // Borrow the Set resource
        self.borrowedSet = self.admin.borrowSet(setID: 1)

        // Borrow the recipient's MomentCollectionPublic capability
        let receiverRef = acct.capabilities.borrow<&{TopShot.MomentCollectionPublic}>(
            /public/MomentCollection
        ) ?? panic("Can't borrow collection reference")

        // Mint moments and return them as a collection
        let collection <- self.borrowedSet.batchMintMoment(playID: 3, quantity: 3)

        // Deposit the minted moments into the recipient's collection
        receiverRef.batchDeposit(tokens: <-collection)
    }

    execute {
        log("Plays minted")
    }
}
