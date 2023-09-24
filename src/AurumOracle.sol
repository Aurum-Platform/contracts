// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title AurumOracle
 * @notice Oracle contract for accessing offchain data onchain (needs to be deployed separately)
 */

contract AurumOracle {
    /**
     * @dev This struct defines the structure of a Trustus packet used for data verification.
     * @param request Identifier for verifying the packet is what is desired,
     *        rather than a packet for some other function/contract
     * @param deadline The Unix timestamp (in seconds) after which the packet
     *        should be rejected by the contract
     * @param payload The payload of the packet
     */
    struct PricePacket {
        bytes32 request;
        uint256 deadline;
        bytes payload;
    }

    // @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;
    // @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    address internal immutable owner;

    /**
     * @notice Records whether an address is trusted as a packet provider
     * @dev provider => value
     */
    mapping(address => bool) internal isTrusted;

    /**
     * @notice NFT Floor Price Value mapping
     */
    mapping(address => PricePacket) public tokenPacket;

    /**
     * @dev This error is raised when an invalid packet is detected during verification.
    */
    error Trustus__InvalidPacket();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Authorized");
        _;
    }

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
        owner = msg.sender;
    }

    /**
     * ========================================================= *
     *                          External                         *
     * ========================================================= *
     */

    function getNFTFloorPrice(address tokenContract) external view returns(uint256) {
        require(tokenContract != address(0), "Invalid token contract");

        uint256 floorPrice = abi.decode(tokenPacket[tokenContract].payload, (uint256));

        return floorPrice;
    }

    function verifyAndSetValue(bytes32 request, PricePacket calldata packet, address tokenContract,  bytes calldata signature) external {
        // verify deadline
        require(block.timestamp < packet.deadline, "Packet is already expired.");

        // verify request
        require(request == packet.request, "Request is invalid");

        (bytes32 r, bytes32 s, uint8 v) = _sigFields(signature);

        // verify signature
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256("VerifyPacket(bytes32 request,uint256 deadline,bytes payload,address tokenContract)"),
                            packet.request,
                            packet.deadline,
                            keccak256(packet.payload),
                            tokenContract
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the recovered signer is trusted
        require((recoveredAddress != address(0)) && isTrusted[recoveredAddress], "Signer is not trusted.");

        tokenPacket[tokenContract] = packet;
    }

    /**
     * ========================================================= *
     *                          Internal                         *
     * ========================================================= *
     */

    function setIsTrusted(address signer, bool isTrusted_) public onlyOwner {
        isTrusted[signer] = isTrusted_;
    }

    function _sigFields(bytes memory signature) internal pure returns(bytes32, bytes32, uint8) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            if (signature.length == 64) {
                // EIP-2098 compact signature
                bytes32 vs;
                assembly {
                    r := mload(add(signature, 0x20))
                    vs := mload(add(signature, 0x40))
                    s := and(
                        vs,
                        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    )
                    v := add(shr(255, vs), 27)
                }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        }

        return(r, s, v);
    }
    
    /**
     * ========================================================= *
     *                    EIP-712 Compliance                     *
     * ========================================================= *
     */

    /**
     * @notice The domain separator used by EIP-712
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /**
     * @notice Computes the domain separator used by EIP-712
     */
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("AurumOracle"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}

// sepolia 0xc17aA70e725d2841141344cA1E96cf7b4Ff4c352