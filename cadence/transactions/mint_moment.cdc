import "TopShot"

transaction {
    let admin: &TopShot.Admin
    let borrowedSet: &TopShot.Set
    let receiverRef: &{TopShot.MomentCollectionPublic}

    prepare(acct: AuthAccount) {
        // Borrow the admin resource from the account's storage
        self.admin = acct.borrow<&TopShot.Admin>(from: /storage/TopShotAdmin)
            ?? panic("Cannot borrow admin resource from storage")

        // Borrow the Set resource using the admin's borrowSet function
        self.borrowedSet = self.admin.borrowSet(setID: 1)

        // Borrow the recipient's MomentCollectionPublic reference
        self.receiverRef = acct.getCapability<&{TopShot.MomentCollectionPublic}>(/public/MomentCollection)
            .borrow()
            ?? panic("Cannot borrow the MomentCollection reference")
    }

    execute {
        // Mint moments using the borrowed set
        let mintedMoments <- self.borrowedSet.batchMintMoment(playID: 3, quantity: 3)

        // Deposit the minted moments into the recipient's collection
        self.receiverRef.batchDeposit(tokens: <-mintedMoments)

        log("Minted and deposited moments into the recipient's collection.")
    }
}
