// SPDX-License-Identifier: MIT OR Apache-2.0
pragma abicoder v2;
pragma solidity >0.6 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PMON is ERC20 {
    uint8 private _decimals;


    constructor() ERC20("PocMon Token", "PMON") {
        _decimals = 9;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
