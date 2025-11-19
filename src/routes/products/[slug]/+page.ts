import { ProductDetailsDocument } from "@gql/graphql";
import { executeGraphQL } from "@lib/graphql";
import type { PageLoad } from "./$types";
import { error } from "@sveltejs/kit";

// Try to import enhanced query
let ProductDetailsEnhancedDocument: any;
try {
	// This will be available after GraphQL generation
	ProductDetailsEnhancedDocument = (await import('@gql/graphql')).ProductDetailsEnhancedDocument;
} catch {
	// Fallback to regular query
	ProductDetailsEnhancedDocument = ProductDetailsDocument;
}

export const load: PageLoad = async ({ params, url }) => {
	try {
		// Get channel from URL params or default
		const channel = url.searchParams.get('channel') || 'default-channel';
		
		// Use enhanced query for Channel 1 or channels that might have variants
		const queryToUse = channel.includes('1') || channel.toLowerCase().includes('channel-1')
			? ProductDetailsEnhancedDocument
			: ProductDetailsDocument;
		
		const data = await executeGraphQL(queryToUse, {
			variables: {
				slug: params.slug,
				channel,
			},
		});

		if (!data.product) {
			throw error(404, "Product not found");
		}

		return {
			product: data.product,
			channel,
		};
	} catch (err) {
		console.error("Failed to fetch product:", err);
		throw error(404, "Product not found or API error");
	}
};
