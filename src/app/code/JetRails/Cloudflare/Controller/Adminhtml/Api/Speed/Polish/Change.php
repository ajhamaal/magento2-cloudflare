<?php

	namespace JetRails\Cloudflare\Controller\Adminhtml\Api\Speed\Polish;

	use JetRails\Cloudflare\Controller\Adminhtml\Action;

	/**
	 * This controller inherits from the base action class and it inherits
	 * helper methods that are contained within it. This controller contains two
	 * actions. One gets the values for the polish and webp settings and the
	 * other changes them.
	 * @version     1.2.4
	 * @package     JetRails® Cloudflare
	 * @author      Rafael Grigorian <development@jetrails.com>
	 * @copyright   © 2018 JETRAILS, All rights reserved
	 * @license     MIT https://opensource.org/licenses/MIT
	 */
	class Change extends Action {

		/**
		 * This action takes in a polish value and a webp value through the
		 * request parameters. It then uses the Cloudflare API model to change
		 * the passed settings.
		 * @return  void
		 */
		public function execute () {
			$response = $this->_api->change (
				$this->_request->getParam ("value"),
				$this->_request->getParam ("webp") === "true"
			);
			return $this->_sendResponse ( $response );
		}

	}
