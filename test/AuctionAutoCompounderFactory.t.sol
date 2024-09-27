// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "test/RelayFactory.t.sol";

import "src/auctionAutoCompounder/AuctionAutoCompounder.sol";
import "src/Optimizer.sol";
import "src/auctionAutoCompounder/AuctionAutoCompounderFactory.sol";

contract AuctionAutoCompounderFactoryTest is RelayFactoryTest {
    bytes AUCTION_FACTORY_BYTECODE = hex'608060405234801561001057600080fd5b50600436106100cf5760003560e01c806350d9d4721161008c5780638ed5e3a3116100665780638ed5e3a31461018d578063ca43205d146101a0578063cbd2bdfd146101b3578063ed3aed79146101c857600080fd5b806350d9d47214610168578063571a26a0146101705780637d97597d1461018357600080fd5b80630935861e146100d4578063165a533d1461010457806319351c8d1461011757806322ebb2731461012f578063336558831461014257806346c715fa14610155575b600080fd5b6100e76100e23660046104b0565b6101d2565b6040516001600160a01b0390911681526020015b60405180910390f35b6100e76101123660046104cb565b6101f2565b610121620f424081565b6040519081526020016100fb565b6100e761013d366004610516565b610211565b6100e761015036600461056b565b61022e565b6000546100e7906001600160a01b031681565b600154610121565b6100e761017e3660046105ca565b610249565b6101216201518081565b6100e761019b3660046105e3565b610273565b6100e76101ae366004610626565b610294565b6101bb6102b4565b6040516100fb9190610659565b6101216206978081565b60006101ec826000336201518062069780620f4240610316565b92915050565b60006102088585858562069780620f4240610316565b95945050505050565b60006102248686868686620f4240610316565b9695505050505050565b600061023e878787878787610316565b979650505050505050565b6001818154811061025957600080fd5b6000918252602090912001546001600160a01b0316905081565b600061028c8484846201518062069780620f4240610316565b949350505050565b60006102ad8383336201518062069780620f4240610316565b9392505050565b6060600180548060200260200160405190810160405280929190818152602001828054801561030c57602002820191906000526020600020905b81546001600160a01b031681526001909101906020018083116102ee575b5050505050905090565b6000610320610427565b6040516339466de560e11b81526001600160a01b03898116600483015288811660248301528781166044830152606482018790526084820186905260a482018590529192509082169063728cdbca9060c401600060405180830381600087803b15801561038c57600080fd5b505af11580156103a0573d6000803e3d6000fd5b505060018054808201825560009182527fb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf60180546001600160a01b0319166001600160a01b03868116918217909255604051918c16945092507fbc4082f61ad2c1141396485591a31655629009271d5910d28313c0460ced44db9190a39695505050505050565b6000805461043d906001600160a01b0316610442565b905090565b6000808260601b9050604051733d602d80600a3d3981f3363d3d373d3d3d363d7360601b81528160148201526e5af43d82803e903d91602b57fd5bf360881b60288201526037816000f0949350505050565b80356001600160a01b03811681146104ab57600080fd5b919050565b6000602082840312156104c257600080fd5b6102ad82610494565b600080600080608085870312156104e157600080fd5b6104ea85610494565b93506104f860208601610494565b925061050660408601610494565b9396929550929360600135925050565b600080600080600060a0868803121561052e57600080fd5b61053786610494565b945061054560208701610494565b935061055360408701610494565b94979396509394606081013594506080013592915050565b60008060008060008060c0878903121561058457600080fd5b61058d87610494565b955061059b60208801610494565b94506105a960408801610494565b9350606087013592506080870135915060a087013590509295509295509295565b6000602082840312156105dc57600080fd5b5035919050565b6000806000606084860312156105f857600080fd5b61060184610494565b925061060f60208501610494565b915061061d60408501610494565b90509250925092565b6000806040838503121561063957600080fd5b61064283610494565b915061065060208401610494565b90509250929050565b6020808252825182820181905260009190848201906040850190845b8181101561069a5783516001600160a01b031683529284019291840191600101610675565b5090969550505050505056fea2646970667358221220fc9ab8b5ef8dd0c8b02910c919c69663d5c799586dc2218a043fc6ce0bc26c5b64736f6c63430008120033';
    AuctionAutoCompounderFactory auctionAutoCompounderFactory;
    AuctionAutoCompounder auctionAutoCompounder;
    Optimizer optimizer;

    constructor() {
        deploymentType = Deployment.FORK;
    }

    // @dev: refer to velodrome-finance/test/BaseTest.sol
    function _setUp() public override {
        vm.etch(0xE6aB098E8582178A76DC80d55ca304d1Dec11AD8, AUCTION_FACTORY_BYTECODE);
        escrow.setTeam(address(owner4));
        keeperRegistry = new Registry(new address[](0));
        optimizerRegistry = new Registry(new address[](0));
        optimizer = new Optimizer(
            address(USDC),
            address(WETH),
            address(FRAX), // OP
            address(VELO),
            address(factory),
            address(router)
        );
        optimizerRegistry.approve(address(optimizer));
        auctionAutoCompounderFactory = new AuctionAutoCompounderFactory(
            address(voter),
            address(router),
            address(keeperRegistry),
            address(optimizerRegistry),
            address(optimizer),
            new address[](0)
        );
        relayFactory = RelayFactory(auctionAutoCompounderFactory);
    }

    function testCreateAuctionAutoCompounderFactoryWithHighLiquidityTokens() public {
        address[] memory highLiquidityTokens = new address[](2);
        highLiquidityTokens[0] = address(FRAX);
        highLiquidityTokens[1] = address(USDC);
        auctionAutoCompounderFactory = new AuctionAutoCompounderFactory(
            address(voter),
            address(router),
            address(keeperRegistry),
            address(optimizerRegistry),
            address(optimizer),
            highLiquidityTokens
        );
        assertTrue(auctionAutoCompounderFactory.isHighLiquidityToken(address(FRAX)));
        assertTrue(auctionAutoCompounderFactory.isHighLiquidityToken(address(USDC)));
    }

    function testCreateAuctionAutoCompounder() public {
        vm.prank(escrow.allowedManager());
        mTokenId = escrow.createManagedLockFor(address(owner));

        assertEq(auctionAutoCompounderFactory.relaysLength(), 0);

        vm.startPrank(address(owner));
        escrow.approve(address(auctionAutoCompounderFactory), mTokenId);
        auctionAutoCompounder = AuctionAutoCompounder(auctionAutoCompounderFactory.createRelay(address(owner), mTokenId, "", new bytes(0)));

        assertFalse(address(auctionAutoCompounder) == address(0));
        assertEq(auctionAutoCompounderFactory.relaysLength(), 1);
        address[] memory auctionAutoCompounders = auctionAutoCompounderFactory.relays();
        assertEq(address(auctionAutoCompounder), auctionAutoCompounders[0]);
        assertEq(escrow.balanceOf(address(auctionAutoCompounder)), 1);
        assertEq(escrow.ownerOf(mTokenId), address(auctionAutoCompounder));

        assertEq(address(auctionAutoCompounder.autoCompounderFactory()), address(auctionAutoCompounderFactory));
        assertEq(address(auctionAutoCompounder.router()), address(router));
        assertEq(address(auctionAutoCompounder.voter()), address(voter));
        assertEq(address(auctionAutoCompounder.optimizer()), address(optimizer));
        assertEq(address(auctionAutoCompounder.ve()), voter.ve());
        assertEq(address(auctionAutoCompounder.velo()), address(VELO));
        assertEq(address(auctionAutoCompounder.distributor()), escrow.distributor());

        assertTrue(auctionAutoCompounder.hasRole(0x00, address(owner))); // DEFAULT_ADMIN_ROLE
        assertTrue(auctionAutoCompounder.hasRole(keccak256("ALLOWED_CALLER"), address(owner)));

        assertEq(auctionAutoCompounder.mTokenId(), mTokenId);
    }

    function testCreateAuctionAutoCompounderByApproved() public {
        vm.prank(escrow.allowedManager());
        mTokenId = escrow.createManagedLockFor(address(owner));

        assertEq(auctionAutoCompounderFactory.relaysLength(), 0);

        vm.startPrank(address(owner));
        escrow.setApprovalForAll(address(auctionAutoCompounderFactory), true);
        escrow.approve(address(owner2), mTokenId);
        vm.stopPrank();
        vm.prank(address(owner2));
        auctionAutoCompounder = AuctionAutoCompounder(auctionAutoCompounderFactory.createRelay(address(owner), mTokenId, "", new bytes(0)));

        assertFalse(address(auctionAutoCompounder) == address(0));
        assertEq(auctionAutoCompounderFactory.relaysLength(), 1);
        address[] memory auctionAutoCompounders = auctionAutoCompounderFactory.relays();
        assertEq(address(auctionAutoCompounder), auctionAutoCompounders[0]);
        assertEq(escrow.balanceOf(address(auctionAutoCompounder)), 1);
        assertEq(escrow.ownerOf(mTokenId), address(auctionAutoCompounder));
        assertEq(auctionAutoCompounder.mTokenId(), mTokenId);
    }

    function testCreateAuctionAutoCompounderByApprovedForAll() public {
        vm.prank(escrow.allowedManager());
        mTokenId = escrow.createManagedLockFor(address(owner));

        assertEq(auctionAutoCompounderFactory.relaysLength(), 0);

        vm.startPrank(address(owner));
        escrow.approve(address(auctionAutoCompounderFactory), mTokenId);
        escrow.setApprovalForAll(address(owner2), true);
        vm.stopPrank();
        vm.prank(address(owner2));
        auctionAutoCompounder = AuctionAutoCompounder(auctionAutoCompounderFactory.createRelay(address(owner), mTokenId, "", new bytes(0)));

        assertFalse(address(auctionAutoCompounder) == address(0));
        assertEq(auctionAutoCompounderFactory.relaysLength(), 1);
        address[] memory auctionAutoCompounders = auctionAutoCompounderFactory.relays();
        assertEq(address(auctionAutoCompounder), auctionAutoCompounders[0]);
        assertEq(escrow.balanceOf(address(auctionAutoCompounder)), 1);
        assertEq(escrow.ownerOf(mTokenId), address(auctionAutoCompounder));
        assertEq(auctionAutoCompounder.mTokenId(), mTokenId);
    }

    function testCannotAddHighLiquidityTokenIfNotOwner() public {
        vm.startPrank(address(owner2));
        assertTrue(msg.sender != auctionAutoCompounderFactory.owner());
        vm.expectRevert("Ownable: caller is not the owner");
        auctionAutoCompounderFactory.addHighLiquidityToken(address(USDC));
    }

    function testCannotAddHighLiquidityTokenIfZeroAddress() public {
        vm.prank(auctionAutoCompounderFactory.owner());
        vm.expectRevert(IRelayFactory.ZeroAddress.selector);
        auctionAutoCompounderFactory.addHighLiquidityToken(address(0));
    }

    function testCannotAddHighLiquidityTokenIfAlreadyExists() public {
        vm.startPrank(auctionAutoCompounderFactory.owner());
        auctionAutoCompounderFactory.addHighLiquidityToken(address(USDC));
        vm.expectRevert(IRelayFactory.HighLiquidityTokenAlreadyExists.selector);
        auctionAutoCompounderFactory.addHighLiquidityToken(address(USDC));
    }

    function testAddHighLiquidityToken() public {
        assertFalse(auctionAutoCompounderFactory.isHighLiquidityToken(address(USDC)));
        assertEq(auctionAutoCompounderFactory.highLiquidityTokens(), new address[](0));
        assertEq(auctionAutoCompounderFactory.highLiquidityTokensLength(), 0);
        vm.prank(auctionAutoCompounderFactory.owner());
        auctionAutoCompounderFactory.addHighLiquidityToken(address(USDC));
        assertTrue(auctionAutoCompounderFactory.isHighLiquidityToken(address(USDC)));
        address[] memory highLiquidityTokens = new address[](1);
        highLiquidityTokens[0] = address(USDC);
        assertEq(auctionAutoCompounderFactory.highLiquidityTokens(), highLiquidityTokens);
        assertEq(auctionAutoCompounderFactory.highLiquidityTokensLength(), 1);
    }
}
