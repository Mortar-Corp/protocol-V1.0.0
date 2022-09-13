//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IVCTokenReceiver.sol";
import "./IVCToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract VCToken is Initializable, IVCToken {

    using AddressUpgradeable for address;

    uint256 public constant BUSINESS_VERIFIED_CREDENTIALS = 1;
    uint256 public constant PERSONAL_VERIFIED_CREDENTIALS = 2;

    //@notice total supply of each token id
    mapping(uint256 => uint256) private _totalSupply;
    //@notice tokentype 'id' that each address holds 
    mapping(address => uint256) private tokenType;


    function mintToken(address to, uint256 id) public virtual override {
        require(id == 1 || id == 2, "VCToken: available 1 for business 2 for personal");
        _beforeTokenTransfer(address(0), to, id);
        emit Transfer(address(0), to, id);
        _acceptanceCheck(address(0), to, id);
    }

    function burnToken(address from, uint256 id) public virtual override {
        require(tokenMinted(id), "VCToken: burn non existing token");
        _beforeTokenTransfer(from, address(0), id);
        emit Transfer(from, address(0), id);
    }

    //@notice transfer is allowed with business VC Token only
    function transferToken(address from, address to) public virtual override {
        uint256 id = 1;
        _beforeTokenTransfer(from, to, id);
        tokenType[to] = id;
        emit Transfer(from, to, id);
        _acceptanceCheck(from, to, id);
    }

    function BusinessOrPersonal(address wallet) public view  override returns(uint256) {
        return tokenType[wallet];
    }

    function totalSupply(uint id) public view override returns(uint256) {
        return _totalSupply[id];
    }

    function tokenMinted(uint256 id) public view override returns(bool) {
        return VCToken.totalSupply(id) > 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 id) private {
        if(from == address(0)) {
            require(
                to != address(0) && AddressUpgradeable.isContract(to), 
                "VCToken: mint to zero address or not contract"
            );
            _totalSupply[id]++;
            tokenType[to] = id;
        }
        if(to == address(0)) {
            _totalSupply[id]--;
            delete tokenType[to];
        }
    }

    function _acceptanceCheck(address from, address to, uint256 id) private {
        if(to.isContract()) {
            try IVCTokenReceiver(to).TokenReceived(from, to, id) returns(bytes4 response) {
                if(response != IVCTokenReceiver.TokenReceived.selector) {
                    revert("VCToken: Receiver rejected token");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("VCToken: transfer to non VCToken receiver");
            }
        }
    }

}