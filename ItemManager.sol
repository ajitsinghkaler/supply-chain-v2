// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";


contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor(ItemManager _parentContract, uint _priceInWei, uint _index) {
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }

    receive() external payable {
        require(pricePaid == 0, "Item is Piad already");
        require(priceInWei == msg.value, "Only full payemnts allowed");
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require (success,"the transaction was not successful cancelling");
    }

    fallback() external {

    }
}

contract ItemManager is Ownable{
    mapping(uint => S_item) public items;

    struct S_item {
        Item _item;
        string _identifier;
        uint _itemPrice;
        SupplyChainState _state;
    }

    event SupplyChainStep(uint _itemIndex, uint _step, address _itemAddress);

    enum SupplyChainState{Created, Paid, Delivered}

    uint itemIndex;

    function createItem(string memory _identifier, uint _price) public onlyOwner {
        Item item = new Item(this, _price, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _price;
        items[itemIndex]._state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex, uint(items[itemIndex]._state), address(this));
        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable{
        require(items[_itemIndex]._itemPrice == msg.value, "Only full payments accepted");
        require(items[_itemIndex]._state == SupplyChainState.Created, "Item has been already paid");
        items[_itemIndex]._state = SupplyChainState.Paid;
        emit SupplyChainStep(itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }

    function triggerDelivery(uint _itemIndex) public onlyOwner{
        require(items[_itemIndex]._state == SupplyChainState.Paid, "Item has been already paid");
        items[_itemIndex]._state = SupplyChainState.Delivered;
        emit SupplyChainStep(itemIndex, uint(items[_itemIndex]._state), address(items[_itemIndex]._item));
    }

}