import "TopShot"
import "NonFungibleToken"
import "ViewResolver"
import "TopShotLocking"

access(all) contract Recipe {
    // This is a snippet extracting the relevant logic from the TopShot contract for demonstration purposes
    // More TopShot Code Above

    // Emitted when a Moment is minted from a Set
    access(all) event MomentMinted(momentID: UInt64, playID: UInt32, setID: UInt32, serialNumber: UInt32, subeditionID: UInt32)

    // Emitted when a moment is withdrawn from a Collection
    access(all) event Withdraw(id: UInt64, from: Address?)
    // Emitted when a moment is deposited into a Collection
    access(all) event Deposit(id: UInt64, to: Address?)

    access(all)
    resource Set {
        access(contract) var retired: {UInt32: Bool}
        access(all) let setID: UInt32
        access(contract) var numberMintedPerPlay: {UInt32: UInt32}

        init(name: String) {
            self.setID = TopShot.nextSetID
            self.numberMintedPerPlay = {}
            self.retired = {}
        }

        // mintMoment mints a new Moment and returns the newly minted Moment
        // 
        // Parameters: playID: The ID of the Play that the Moment references
        //
        // Pre-Conditions:
        // The Play must exist in the Set and be allowed to mint new Moments
        //
        // Returns: The NFT that was minted
        // 
        access(all) fun mintMoment(playID: UInt32): @NFT {
            pre {
                self.retired[playID] != nil: "Cannot mint the moment: This play doesn't exist."
                !self.retired[playID]!: "Cannot mint the moment from this play: This play has been retired."
            }

            // Gets the number of Moments that have been minted for this Play
            // to use as this Moment's serial number
            let numInPlay = self.numberMintedPerPlay[playID]!

            // Mint the new moment
            let newMoment: @NFT <- create NFT(serialNumber: numInPlay + UInt32(1),
                                              playID: playID,
                                              setID: self.setID,
                                              subeditionID: 0)

            // Increment the count of Moments minted for this Play
            self.numberMintedPerPlay[playID] = numInPlay + UInt32(1)

            return <-newMoment
        }

        // batchMintMoment mints an arbitrary quantity of Moments 
        // and returns them as a Collection
        //
        // Parameters: playID: the ID of the Play that the Moments are minted for
        //             quantity: The quantity of Moments to be minted
        //
        // Returns: Collection object that contains all the Moments that were minted
        //
        access(all)
        fun batchMintMoment(playID: UInt32, quantity: UInt64): @Collection {
            let newCollection <- create Collection()
            var i: UInt64 = 0
            while i < quantity {
                newCollection.deposit(token: <-self.mintMoment(playID: playID))
                i = i + UInt64(1)
            }

            return <-newCollection
        }
    }

    access(all)
    struct MomentData {

        // The ID of the Set that the Moment comes from
        access(all) let setID: UInt32

        // The ID of the Play that the Moment references
        access(all) let playID: UInt32

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        access(all) let serialNumber: UInt32

        init(setID: UInt32, playID: UInt32, serialNumber: UInt32) {
            self.setID = setID
            self.playID = playID
            self.serialNumber = serialNumber
        }

    }

    // The resource that represents the Moment NFTs
    //
    access(all)
    resource NFT: NonFungibleToken.NFT {

        // Global unique moment ID
        access(all)
        let id: UInt64
        
        // Struct of Moment metadata
        access(all)
        let data: MomentData

        access(all) var totalSupply: UInt64

        init(serialNumber: UInt32, playID: UInt32, setID: UInt32, subeditionID: UInt32) {
            // Increment the global Moment IDs
            self.totalSupply = TopShot.totalSupply + UInt64(1)
            self.id = TopShot.totalSupply

            // Set the metadata struct
            self.data = MomentData(setID: setID, playID: playID, serialNumber: serialNumber)

            emit MomentMinted(momentID: self.id,
                              playID: playID,
                              setID: self.data.setID,
                              serialNumber: self.data.serialNumber,
                              subeditionID: subeditionID)
        }

        // Placeholder implementation for getViews and resolveView
        access(all)
        view fun getViews(): [Type] {
            return []
        }

        access(all)
        fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        access(all) fun createEmptyCollection(): @Collection {
        return <- create Collection()

        
    }

    }

    // Collection is a resource that every user who owns NFTs 
    // will store in their account to manage their NFTS
    //
    access(all) resource Collection: MomentCollectionPublic, NonFungibleToken.Collection {
        // Dictionary of Moment conforming tokens
        // NFT is a resource type with a UInt64 ID field
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        init() {
            self.ownedNFTs <- {}
        }

        // Return a list of NFT types that this receiver accepts
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@TopShot.NFT>()] = true
            return supportedTypes
        }

        // Return whether or not the given type is accepted by the collection
        // A collection that can accept any type should just return true by default
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            if type == Type<@TopShot.NFT>() {
                return true
            }
            return false
        }

        // Return the amount of NFTs stored in the collection
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }

        // Create an empty Collection for TopShot NFTs and return it to the caller
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- TopShot.createEmptyCollection(nftType: Type<@TopShot.NFT>())
        }

        // withdraw removes an Moment from the Collection and moves it to the caller
        //
        // Parameters: withdrawID: The ID of the NFT 
        // that is to be removed from the Collection
        //
        // returns: @NonFungibleToken.NFT the token that was withdrawn
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {

            // Borrow nft and check if locked
            let nft = self.borrowNFT(withdrawID)
                ?? panic("Cannot borrow: empty reference")
            if TopShotLocking.isLocked(nftRef: nft) {
                panic("Cannot withdraw: Moment is locked")
            }

            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Cannot withdraw: Moment does not exist in the collection")

            emit Withdraw(id: token.id, from: self.owner?.address)

            // Return the withdrawn token
            return <-token
        }

        // batchWithdraw withdraws multiple tokens and returns them as a Collection
        //
        // Parameters: ids: An array of IDs to withdraw
        //
        // Returns: @NonFungibleToken.Collection: A collection that contains
        //                                        the withdrawn moments
        //
        access(NonFungibleToken.Withdraw) fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection} {
            // Create a new empty Collection
            var batchCollection <- create Collection()
            
            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }
            
            // Return the withdrawn tokens
            return <-batchCollection
        }

        // deposit takes a Moment and adds it to the Collections dictionary
        //
        // Paramters: token: the NFT to be deposited in the collection
        //
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            
            // Cast the deposited token as a TopShot NFT to make sure
            // it is the correct type
            let token <- token as! @TopShot.NFT

            // Get the token's ID
            let id = token.id

            // Add the new token to the dictionary
            let oldToken <- self.ownedNFTs[id] <- token

            // Only emit a deposit event if the Collection 
            // is in an account's storage
            if self.owner?.address != nil {
                emit Deposit(id: id, to: self.owner?.address)
            }

            // Destroy the empty old token that was "removed"
            destroy oldToken
        }

        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        access(all) fun batchDeposit(tokens: @{NonFungibleToken.Collection}) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
        }

        // lock takes a token id and a duration in seconds and locks
        // the moment for that duration
        access(NonFungibleToken.Update) fun lock(id: UInt64, duration: UFix64) {
            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: id) 
                ?? panic("Cannot lock: Moment does not exist in the collection")

            TopShot.emitNFTUpdated(&token as auth(NonFungibleToken.Update) &{NonFungibleToken.NFT})

            // pass the token to the locking contract
            // store it again after it comes back
            let oldToken <- self.ownedNFTs[id] <- TopShotLocking.lockNFT(nft: <- token, duration: duration)

            destroy oldToken
        }

        // batchLock takes an array of token ids and a duration in seconds
        // it iterates through the ids and locks each for the specified duration
        access(NonFungibleToken.Update) fun batchLock(ids: [UInt64], duration: UFix64) {
            // Iterate through the ids and lock them
            for id in ids {
                self.lock(id: id, duration: duration)
            }
        }

        // unlock takes a token id and attempts to unlock it
        // TopShotLocking.unlockNFT contains business logic around unlock eligibility
        access(NonFungibleToken.Update) fun unlock(id: UInt64) {
            // Remove the nft from the Collection
            let token <- self.ownedNFTs.remove(key: id) 
                ?? panic("Cannot lock: Moment does not exist in the collection")

            TopShot.emitNFTUpdated(&token as auth(NonFungibleToken.Update) &{NonFungibleToken.NFT})

            // Pass the token to the TopShotLocking contract then get it back
            // Store it back to the ownedNFTs dictionary
            let oldToken <- self.ownedNFTs[id] <- TopShotLocking.unlockNFT(nft: <- token)

            destroy oldToken
        }

        // batchUnlock takes an array of token ids
        // it iterates through the ids and unlocks each if they are eligible
        access(NonFungibleToken.Update) fun batchUnlock(ids: [UInt64]) {
            // Iterate through the ids and unlocks them
            for id in ids {
                self.unlock(id: id)
            }
        }

        // getIDs returns an array of the IDs that are in the Collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT Returns a borrowed reference to a Moment in the Collection
        // so that the caller can read its ID
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        //
        // Note: This only allows the caller to read the ID of the NFT,
        // not any topshot specific data. Please use borrowMoment to 
        // read Moment data.
        //
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        // borrowMoment returns a borrowed reference to a Moment
        // so that the caller can read data and call methods from it.
        // They can use this to read its setID, playID, serialNumber,
        // or any of the setData or Play data associated with it by
        // getting the setID or playID and reading those fields from
        // the smart contract.
        //
        // Parameters: id: The ID of the NFT to get the reference for
        //
        // Returns: A reference to the NFT
        access(all) view fun borrowMoment(id: UInt64): &TopShot.NFT? {
            return self.borrowNFT(id) as! &TopShot.NFT?
        }

        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? {
                return nft as &{ViewResolver.Resolver}
            }
            return nil
        }

    }

    // This is the interface that users can cast their Moment Collection as
    // to allow others to deposit Moments into their Collection. It also allows for reading
    // the IDs of Moments in the Collection.
    /// Deprecated: This is no longer used for defining access control anymore.
    access(all) resource interface MomentCollectionPublic : NonFungibleToken.CollectionPublic {
        access(all) fun batchDeposit(tokens: @{NonFungibleToken.Collection})
        access(all) fun borrowMoment(id: UInt64): &TopShot.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow Moment reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // More TopShot Code Below
}