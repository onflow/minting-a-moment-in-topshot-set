import "TopShot"

transaction {
    let admin: &TopShot.Admin
    let borrowedSet: &TopShot.Set
    let receiverRef: &{TopShot.MomentCollectionPublic}

    prepare(acct: auth(Storage, Capabilities) &Account) {
        // Issue a capability for the admin resource and publish it for borrowing
        let adminCap = acct.capabilities.storage.issue<&TopShot.Admin>(/storage/TopShotAdmin)
        acct.capabilities.publish(adminCap, at: /public/TopShotAdminCap)

        // Borrow the admin resource using the published capability
        self.admin = acct.capabilities.borrow<&TopShot.Admin>(/public/TopShotAdminCap)
            ?? panic("Cannot borrow admin resource from storage")

            // Ensure the Set resource exists
        if acct.storage.borrow<&TopShot.Set>(from: /storage/TopShotSet) == nil {
            let newSet = self.admin.createSet(name: "test_set")
            acct.storage.save(newSet, to: /storage/TopShotSet)
        }       

        // Borrow the specified Set from the admin
        self.borrowedSet = self.admin.borrowSet(setID: 1) 

        // Issue a capability for the MomentCollection and publish it
        let momentCap = acct.capabilities.storage.issue<&{TopShot.MomentCollectionPublic}>(/storage/MomentCollection)
        acct.capabilities.publish(momentCap, at: /public/MomentCollectionCap)

        // Borrow the recipient's MomentCollectionPublic reference
        self.receiverRef = acct.capabilities.borrow<&{TopShot.MomentCollectionPublic}>(/public/MomentCollectionCap)
            ?? panic("Cannot borrow the MomentCollection reference")
    }

    execute {
         // Create plays if they don't already exist
        let playIDs: [UInt32] = [1, 2, 3]
        for playID in playIDs {
            if TopShot.getPlayMetaData(playID: playID) == nil {
                let metadata: {String: String} = {
                    "Player": "Player Name ".concat(playID.toString()),
                    "Play": "Play Description ".concat(playID.toString())
                }
                self.admin.createPlay(metadata: metadata)
            }
        }    

        self.borrowedSet.addPlay(playID: 1)
        self.borrowedSet.addPlay(playID: 2)
        self.borrowedSet.addPlay(playID: 3)

        // Mint moments using the borrowed set
        let mintedMoments <- self.borrowedSet.batchMintMoment(playID: 1, quantity: 3)

        // Deposit the minted moments into the recipient's collection
        self.receiverRef.batchDeposit(tokens: <-mintedMoments)

        log("Minted and deposited moments into the recipient's collection.")
    }
}
