pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC165.sol";

contract MyERC721Implementation is ERC721, ERC165
{
    uint256 private _currentTokenId;

    mapping(address => uint256[]) private _ownersToTokenIds;
    mapping(uint256 => address) private _tokenIdsToOwners;
    mapping(uint256 => address) private _tokenIdsToApprovedAddress; // only 1 approved address possible
    mapping(address => address[]) private _ownersToAuthorizedOperators;

    error ZeroAddressQueried();
    error NFTAssignedToZeroAddress();
    error NotCurrentOwner();
    error TokenIdNotValid();
    error InvalidFunctionSignature();

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) override external view returns (uint256)
    {
        if (_owner == address(0)) // TODO: See if this is the right way of saying "zero address"
        {
            revert ZeroAddressQueried();
        }
        return _ownersToTokenIds[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) override external view returns (address)
    {
        if (_tokenIdsToOwners[_tokenId] == address(0))
        {
            revert NFTAssignedToZeroAddress();
        }
        return _tokenIdsToOwners[_tokenId];
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable
    {
        if ((msg.sender != _tokenIdsToOwners[_tokenId]) || (msg.sender != _tokenIdsToApprovedAddress[_tokenId]))
        // TODO: I don't check if msg.sender is an authorized operator
        {
            revert NotCurrentOwner();
        }
        if (_from != _tokenIdsToOwners[_tokenId])
        {
            revert NotCurrentOwner();
        }
        if (_to == address(0))
        {
            revert NFTAssignedToZeroAddress();
        }
        if (_tokenId > _currentTokenId) // TODO: not sure if this is the right check for "`_tokenId` is not a valid NFT"
        {
            revert TokenIdNotValid();
        }
        _tokenIdsToOwners[_tokenId] = _to;
        uint256[] memory currentTokenIdsFromSender = _ownersToTokenIds[_from];
        // TODO: Think about how to code the below commented-out chunk of this function
        // I can't push() into memory, and storage isn't really appropriate for this either (neither is calldata)
        /*
        uint256[] memory newTokenIdsFromSender;
        for (uint256 i = 0; i < currentTokenIdsFromSender.length; i++) // TODO: Think of a more efficient way to implement this
        {
            if (currentTokenIdsFromSender[i] != _tokenId)
            {
                newTokenIdsFromSender.push(currentTokenIdsFromSender[i]);
            }
        }
        _ownersToTokenIds[_from] = newTokenIdsFromSender;
        */
        // check if _to is a smart contract
        // code taken from https://stackoverflow.com/questions/37644395/how-to-find-out-if-an-ethereum-address-is-a-contract
        uint size;
        assembly { size := extcodesize(_to) }
        if (size > 0)
        {
            (bool success, bytes memory returnValue) = _to.call(abi.encodeWithSignature("onERC721Received"));
            if (keccak256(returnValue) != keccak256("onERC721Received(address,address,uint256,bytes)"))
            {
                revert InvalidFunctionSignature();
            }
        }
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable
    {
        this.safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable
    {
        this.safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) override external payable
    {
      if (msg.sender != _tokenIdsToOwners[_tokenId]) // TODO: I don't check if msg.sender is an authorized operator of the current owner
      {
          revert NotCurrentOwner();
      }
      _tokenIdsToApprovedAddress[_tokenId] = _approved;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) override external
    {
        if (_approved == true)
        {
            _ownersToAuthorizedOperators[msg.sender].push(_operator);
        }
        else
        {
            // based on https://ethereum.stackexchange.com/questions/66977/remove-array-specific-value
            // TODO: maybe there's a more gas-efficient way to do this?

            // TODO: Think about how to code the below commented-out chunk of this function
            // I can't push() into memory, and storage isn't really appropriate for this either (neither is calldata)
            /*
            address[] memory newOwnersToAuthorizedOperators;

            for (uint i = 0; i < _ownersToAuthorizedOperators[msg.sender].length; i++)
            {
                if(_ownersToAuthorizedOperators[msg.sender][i] != _operator)
                {
                    newOwnersToAuthorizedOperators.push(_ownersToAuthorizedOperators[msg.sender][i]);
                }
            }
            */
            emit ApprovalForAll(msg.sender, _operator, _approved);
          }
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) override external view returns (address)
    {
      if (_tokenId > _currentTokenId) // TODO: not sure if this is the right check for "`_tokenId` is not a valid NFT"
      {
          revert TokenIdNotValid();
      }
      if (_tokenIdsToApprovedAddress[_tokenId] != address(0))
      {
          return _tokenIdsToApprovedAddress[_tokenId];
      }
      else
      {
          return address(0);
      }
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) override external view returns (bool)
    {
        address[] memory authorizedAddressesForOwner = _ownersToAuthorizedOperators[_owner];
        for (uint256 i = 0; i < authorizedAddressesForOwner.length; i++) // TODO: see if there's a more efficient way to implement this
        {
            if (authorizedAddressesForOwner[i] == _operator)
            {
                return true;
            }
        }
        return false;
    }

    // -------------------------- FROM ERC-165 ------------------------------------------

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) override external view returns (bool)
    {
        // TODO: how to do this?
        return false;
    }
}
