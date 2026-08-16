// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Autonomous Mobile Logistics & Direct Production Contract
 * @notice РђСЂС…РёС‚РµРєС‚СѓСЂР° РґРµС†РµРЅС‚СЂР°Р»РёР·РѕРІР°РЅРЅРѕРіРѕ СЂР°СЃРїСЂРµРґРµР»РµРЅРёСЏ Р±РµР· СЃРєР»Р°РґРѕРІ Рё РїРѕСЃСЂРµРґРЅРёРєРѕРІ.
 * @dev РћС‚СЃРµРєР°РµС‚ РєР»Р°СЃСЃРёС‡РµСЃРєРёР№ Р±СЋСЂРѕРєСЂР°С‚РёС‡РµСЃРєРёР№ РєРѕРЅС‚СѓСЂ Рё РїСЂРѕРјРµР¶СѓС‚РѕС‡РЅС‹Рµ РЅР°С†РµРЅРєРё.
 */
contract AutonomousLogisticsNode {

    struct TransitOrder {
        address creator;
        address payable operator;
        uint256 rawMaterialCost;
        uint256 energyCost;
        uint256 finalPrice;
        bool inTransit;
        bool completed;
        bool disputed;
    }

    mapping(bytes32 => TransitOrder) public orders;
    mapping(address => bool) public authorizedNodes;
    
    event OrderDispatched(bytes32 indexed orderId, address indexed operator, uint256 finalPrice);
    event OrderCompleted(bytes32 indexed orderId);
    event AnomalyIsolated(bytes32 indexed orderId, string reason);

    modifier onlyAuthorized() {
        require(authorizedNodes[msg.sender], "Node not authorized in the decentralized mesh.");
        _;
    }

    constructor() {
        authorizedNodes[msg.sender] = true;
    }

    function registerNode(address _node) external onlyAuthorized {
        authorizedNodes[_node] = true;
    }

    function dispatchTransitProduction(
        bytes32 _orderId,
        address payable _operator,
        uint256 _rawCost,
        uint256 _energyCost,
        uint256 _targetPrice
    ) external payable {
        require(orders[_orderId].creator == address(0), "Order ID already exists.");
        require(msg.value >= _targetPrice, "Insufficient funds deposited for direct production.");

        orders[_orderId] = TransitOrder({
            creator: msg.sender,
            operator: _operator,
            rawMaterialCost: _rawCost,
            energyCost: _energyCost,
            finalPrice: _targetPrice,
            inTransit: true,
            completed: false,
            disputed: false
        });

        emit OrderDispatched(_orderId, _operator, _targetPrice);
    }

    function verifyAndFinalize(bytes32 _orderId) external onlyAuthorized {
        TransitOrder storage order = orders[_orderId];
        require(order.inTransit, "Order is not active in transit.");
        require(!order.completed && !order.disputed, "Order already finalized or isolated.");

        order.inTransit = false;
        order.completed = true;

        // РџСЂСЏРјРѕР№ СЂР°СЃС‡РµС‚ Р±РµР· РїРѕСЃСЂРµРґРЅРёРєРѕРІ Рё РєРѕРјРёСЃСЃРёР№ РїР°СЂР°Р·РёС‚РёС‡РµСЃРєРёС… РЅР°РґСЃС‚СЂРѕРµРє
        uint256 totalCost = order.rawMaterialCost + order.energyCost;
        uint256 operatorMargin = order.finalPrice - totalCost;

        order.operator.transfer(totalCost + operatorMargin);

        emit OrderCompleted(_orderId);
    }

    function isolateAnomaly(bytes32 _orderId, string calldata _reason) external onlyAuthorized {
        TransitOrder storage order = orders[_orderId];
        require(order.inTransit, "Order not active.");

        order.inTransit = false;
        order.disputed = true;

        // РђРІС‚РѕРјР°С‚РёС‡РµСЃРєРёР№ РІРѕР·РІСЂР°С‚ СЃСЂРµРґСЃС‚РІ СЃРѕР·РґР°С‚РµР»СЋ РїСЂРё РїРѕРїС‹С‚РєРµ РІРјРµС€Р°С‚РµР»СЊСЃС‚РІР° РёР»Рё СЃР±РѕСЏ
        payable(order.creator).transfer(address(this).balance < order.finalPrice ? address(this).balance : order.finalPrice);

        emit AnomalyIsolated(_orderId, _reason);
    }
}
